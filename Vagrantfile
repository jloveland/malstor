# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'precise64'
  config.vm.box_url = 'http://files.vagrantup.com/precise64.box'

  # Manage /etc/hosts on host and VMs
  config.hostmanager.enabled = false
  config.hostmanager.manage_host = true
  config.hostmanager.include_offline = true
  config.hostmanager.ignore_private_ip = false

  config.vm.define :server do |server_config|
    server_config.vm.hostname = 'malstor-server'
    # server_config.vm.network "public_network", bridge: 'eth0'
    # server_config.vm.network "forwarded_port", guest: 443, host: 8443
    # server_config.vm.network "forwarded_port", guest: 8080, host: 8080
    server_config.vm.provider :virtualbox do |vb|
      #vb.gui = true
      vb.customize ["modifyvm", :id, "--memory", "4096"]
      # TODO: Find configsettings for two cpus
    end
    # server_config.vm.provider "vmware_workstation" do |vw|
    #   #vw.gui = true
    #   vw.vmx["memsize"] = "4096"
    #   vw.vmx["numvcpus"] = "2"
    # end
    server_config.vm.network :private_network, ip: "10.211.55.100"
    # TODO: figure out how to provision crits
    server_config.vm.provision "shell", path: 'script/crits.sh'

  end

  config.vm.define :client do |client_config|
    client_config.vm.box = 'ubuntu-1404-desktop'
    # client_config.vm.box_url = 'https://vagrantcloud.com/janihur/boxes/ubuntu-1404-desktop'
    client_config.vm.hostname = 'malstor-client'
    client_config.vm.provider :virtualbox do |v|
      v.gui = true
      v.name = "malstor-client"
      v.customize ["modifyvm", :id, "--memory", "2048"]
    end
    # client_config.vm.provider "vmware_workstation" do |vw|
    #   #vw.gui = true
    #   vw.vmx["memsize"] = "2048"
    #   vw.vmx["numvcpus"] = "2"
    # end
    client_config.vm.network :private_network, ip: "10.211.55.101"
    # client_config.vm.provision :shell, path: "script/TODO.sh"
    client_config.vm.provision "shell" do |s|
      s.inline = "apt-get install xfce4 -y"
    end
  end

end
