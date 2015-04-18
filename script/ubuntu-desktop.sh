#!/bin/bash
apt-get update
apt-get install -y xfce4 virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11
VBoxClient-all
add-apt-repository ppa:gnome3-team/gnome3
apt-get install -y gnome-shell
apt-get install -y ubuntu-desktop
sudo startxfce4&
sudo reboot
