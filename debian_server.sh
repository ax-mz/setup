#!/bin/bash

#### Debian Server

if [[ $UID != 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi

packages=(sudo bash-completion curl openssh-server)

apt -qq update && apt -qq upgrade -y
apt -qq install ${packages[@]} -y

# Adding non-root user to sudoers 
user=$(id -nu 1000)
echo -e "\n$user\tALL=(ALL:ALL) ALL" >> /etc/sudoers

# Red prompt for root
echo -e 'PS1="${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /root/.bashrc
# Green prompt for user
sed -i -e 's|^#force_color.*|force_color_prompt=yes|' /home/$user/.bashrc

#  Allow root ssh
sed -i -e 's|^#PermitRoot.*|PermitRootLogin yes|' /etc/ssh/sshd_config
systemctl enable ssh
systemctl restart ssh

# Aliases
echo -e "\nalias up='apt update && apt upgrade -y && apt autoremove -y'" >> /root/.bashrc
echo "alias shutdown='shutdown -h now'" >> /root/.bashrc
echo "alias ipw='curl https://ifconfig.me/ && echo '" >> /root/.bashrc
echo "alias ipw='curl https://ifconfig.me/ && echo '" >> /home/$user/.bashrc

source ~/.bashrc
source /home/$user/.bashrc
