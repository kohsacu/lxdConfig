#!/bin/sh

#
# $ lxc launch images:alpine/3.12 <CONTAINER_NAME>
# $ lxc file push ./lxd-bastionx-alpine.sh <CONTAINER_NAME>/root/
# $ lxc exec <CONTAINER_NAME> -- sh /root/lxd-bastionx-alpine.sh
#

echo -e "\n== package =="
apk --no-cache info
apk --no-cache add \
openrc \
openssh \
shadow \

echo -e "\n== useradd =="
groupadd bastion
useradd --create-home --comment "Operation User" --shell /bin/ash -g bastion bastion
echo "bastion:login_secret" | chpasswd
mkdir -p                 /home/bastion/.ssh
chmod 700                /home/bastion/.ssh
chown -R bastion:bastion /home/bastion/.ssh

echo -e "\n== sshd_config =="
cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config.debug
sed -i 's/^#\(.*HostKey \/etc\/ssh\/ssh_host_ed25519_key\)/\1/' /etc/ssh/sshd_config
sed -i 's/^#\(.*PubkeyAuthentication yes\)/\1/' /etc/ssh/sshd_config
sed -i 's/\(^#PasswordAuthentication yes\)/\1\nPasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\(.*PermitEmptyPasswords no\)/\1/' /etc/ssh/sshd_config
sed -i 's/\(^#ChallengeResponseAuthentication yes\)/\1\nChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i 's/\(#LogLevel INFO\)/\1\nLogLevel VERBOSE/' /etc/ssh/sshd_config
{ \
  echo -e "\n# == Add sshd Recommended setting =="; \
  echo "Protocol 2"; \
  echo "PermitRootLogin no"; \
} | tee -a /etc/ssh/sshd_config
diff -us /etc/ssh/sshd_config.debug /etc/ssh/sshd_config

echo -e "\n== service =="
rc-update add sshd
/etc/init.d/sshd start
rc-status

