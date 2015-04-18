#!/bin/bash

apt-get update
apt-get install -y --force-yes language-pack-nb
apt-get install -y --force-yes vim git htop most

cd /root
git clone https://github.com/crits/crits.git

cat <<EOF
# please ssh into the server:
vagrant ssh server

# and run the folllowing:
sudo -i
cd /root/crits/
sh script/bootstrap

# to re-launch server, run the following:
sudo -i
cd /root/crits/
python manage.py runserver 0.0.0.0:8080
EOF
