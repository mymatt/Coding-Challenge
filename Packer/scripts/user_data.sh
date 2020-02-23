#!/usr/bin/env bash

# install ansible
sudo /usr/bin/apt update
sudo /usr/bin/apt -y upgrade
sudo /usr/bin/apt -y install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt -y install ansible

echo "127.0.0.1 $(hostname)" | sudo tee --append /etc/hosts
