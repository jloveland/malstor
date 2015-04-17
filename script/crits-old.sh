#! /bin/bash

#DEVELOPMENT CHOICE#
# GATEWAY=$(ip route show | grep ^default | cut -d' ' -f 3)
# HOST="$(echo -n $GATEWAY | cut -d . -f 1-3).$(($(echo $GATEWAY | cut -d . -f 4 )-1))"
# echo "Acquire::http { Proxy \"http://$HOST:3142\"; };" >> /etc/apt/apt.conf.d/01proxy
#DEVELOPMENT CHOICE#

# cat > /etc/apt/sources.list  <<EOF
# deb http://archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse
# deb http://archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse
# deb http://archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse
# deb http://security.ubuntu.com/ubuntu precise-security main restricted universe multiverse
# deb http://archive.canonical.com/ubuntu precise partner
# deb http://extras.ubuntu.com/ubuntu precise main
# EOF

apt-get update
apt-get install -y --force-yes language-pack-nb
apt-get install -y --force-yes vim git htop most

cd /root

#DEVELOPMENT CHOICE#
#cp -R /vagrant/git-repos/crits_dependencies /root/crits_dependencies
# Comment out these two lines if using the line over
git clone https://github.com/crits/crits_dependencies.git
#DEVELOPMENT CHOICE#


cd /root/crits_dependencies
git pull
./install_dependencies.sh

# "python manage.py create_default_collections" requires python-magic
apt-get install -y --force-yes python-magic

echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle

mkdir /data
cd /data

#DEVELOPMENT CHOICE#
# cp -R /vagrant/git-repos/crits_services /data/crits_services
# Comment out this line if using the line over
git clone https://github.com/crits/crits_services.git
#DEVELOPMENT CHOICE#

cd /data/crits_services
git pull

mkdir -p /data/db

cd /data

#DEVELOPMENT CHOICE#
# cp -R /vagrant/git-repos/crits /data/crits
# Comment out this line if using the line over
git clone https://github.com/crits/crits.git
#DEVELOPMENT CHOICE#

cd /data/crits
git pull
git checkout stable_3 # more stable envrionment?

# Setting up your single server instance of MongoDB
cd /data/crits/contrib/mongo/UMA
apt-get install -y --force-yes mongodb-server
./mongod_start.sh

# Verify this is working by connecting to it with the following command:
echo "quit()" | mongo

# Create a crits user on your system:
# adduser crits
useradd -m -p crits crits

# Modify the crits group to contain your webserver user, any users running CRITs cronjobs, and any users running CRITs scripts.
usermod -a -G crits root
usermod -a -G crits www-data
usermod -a -G crits vagrant

cd /data/crits
touch logs/crits.log
chgrp -R crits logs
chmod 664 logs/crits.log
cd /data/crits/crits/config
cp database_example.py database.py

SECRET_KEY=$(python -c 'from django.utils.crypto import get_random_string as grs; print grs(50, "abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)")')

# Drop the & so we can use sed
SECRET_KEY=$(python -c 'from django.utils.crypto import get_random_string as grs; print grs(50, "abcdefghijklmnopqrstuvwxyz0123456789!@#$%^*(-_=+)")')
sed -i -e "s/SECRET_KEY = ''/SECRET_KEY = '${SECRET_KEY}'/" database.py

cd /data/crits
python manage.py create_default_collections

# For HEAD 2014-07-24
#python manage.py users --adduser -A --email=vagrant@example.com --firstname=Va --lastname=Grant --organization=ExampleOrg --setactive --username=vagrant

# for stable_3
python manage.py adduser -a --email=vagrant@example.com --firstname=Va --lastname=Grant --organization=ExampleOrg --username=vagrant > user.log

grep 'Temp password' user.log | sed -e 's/Temp password:/User: vagrant\nPassword: /' > /home/vagrant/CRITS_PASSWORD
#rm user.log

# This should probably be changed
python manage.py setconfig allowed_hosts '*'

/etc/init.d/apache2 stop

rm -rf /etc/apache2/sites-available

cd /data/crits/extras
cp *.conf /etc/apache2
cp -r sites-available /etc/apache2

rm /etc/apache2/sites-enabled/*


#ln -s /etc/apache2/sites-available/default-ssl /etc/apache2/sites-enabled/default-ssl
mv /etc/apache2/sites-available/default-ssl /etc/apache2/sites-available/default-ssl.conf
a2ensite default-ssl

cd /tmp

# Since this is for testing, we will reuse the password for the admin user
#openssl req -new > new.cert.csr
yes '' | openssl req -new -passout pass:${SECRET_KEY} > new.cert.csr

#openssl rsa -in privkey.pem -out new.cert.key
openssl rsa -passin pass:${SECRET_KEY} -in privkey.pem -out new.cert.key

openssl x509 -in new.cert.csr -out new.cert.cert -req -signkey new.cert.key -days 1825

cp new.cert.cert /etc/ssl/certs/crits.crt
cp new.cert.key /etc/ssl/private/crits.plain.key

a2enmod ssl

echo 'export LANG=en_US.UTF-8' >> /etc/apache2/envvars

# Some required modifications to the apache2.conf-file
sed -i -e 's%^LockFile /var/lock/apache2/accept.lock$%Mutex file:${APACHE_LOCK_DIR} default%' /etc/apache2/apache2.conf
sed -i -e 's%^Include /etc/apache2/conf.d/$%IncludeOptional conf-enabled/*.conf%' /etc/apache2/apache2.conf
sed -i -e 's%^Include /etc/apache2/sites-enabled/$%IncludeOptional sites-enabled/*.conf%' /etc/apache2/apache2.conf

/etc/init.d/apache2 start

echo -e '0 * * * *       cd /data/crits/ && /usr/bin/python manage.py mapreduces\n0 * * * *       cd /data/crits/ && /usr/bin/python manage.py generate_notifications' | crontab - -u crits

cat /home/vagrant/CRITS_PASSWORD
