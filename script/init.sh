#!/bin/sh
echo "Are you root?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) 
            a=
            break;;
        No )
            a=sudo
            break;;
    esac
done

echo ""
echo ""

echo "Create a non-root user?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) 
            echo "Enter a username"
            read name
            $a adduser $name
            $a usermod -aG sudo $name
            if [ -d "~/.ssh" ]; then\
                $a rsync --archive --chown=$name:$name ~/.ssh /home/$name
            fi
            break;;
        No ) break;;
    esac
done

echo ""
echo ""

#SSH
echo "Enter ssh custom port"
read port

$a sed -re 's/^(\#)(Port)([[:space:]]+)(.*)/\2\3\4/' -i /etc/ssh/sshd_config
$a sed -re 's/^(\#)(PermitRootLogin)([[:space:]]+)(.*)/\2\3\4/' -i /etc/ssh/sshd_config
$a sed -re 's/^(\#)(PasswordAuthentication)([[:space:]]+)(.*)/\2\3\4/' -i /etc/ssh/sshd_config
$a sed -re 's/^(\#)(MaxAuthTries)([[:space:]]+)(.*)/\2\3\4/' -i /etc/ssh/sshd_config
$a sed -re 's/^(\#)(LoginGraceTime)([[:space:]]+)(.*)/\2\3\4/' -i /etc/ssh/sshd_config
$a sed -re 's/^(\#)(PermitEmptyPasswords)([[:space:]]+)(.*)/\2\3\4/' -i /etc/ssh/sshd_config

$a sed -re 's/^(PasswordAuthentication)([[:space:]]+)yes/\1\2no/' -i /etc/ssh/sshd_config
$a sed -re 's/^(PermitRootLogin)([[:space:]]+)yes/\1\2no/' -i /etc/ssh/sshd_config
$a sed -re 's/^(PermitRootLogin)([[:space:]]+)prohibit-password/\1\2no/' -i /etc/ssh/sshd_config
$a sed -re "s/^(Port)([[:space:]]+)22/\1\2$port/" -i /etc/ssh/sshd_config

echo ""
echo ""

#IPTABLES
$a apt update
$a apt install iptables-persistent htop -y
$a iptables --policy INPUT DROP
$a iptables -A INPUT -i lo -j ACCEPT
$a iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
$a iptables -A INPUT -p tcp --dport $port -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
$a netfilter-persistent save

echo ""
echo ""

#SWAP
$a fallocate -l 1G /swapfile
$a chmod 600 /swapfile
$a mkswap /swapfile
$a swapon /swapfile
$a cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | $a tee -a /etc/fstab
echo 'vm.swappiness=10' | $a tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | $a tee -a /etc/sysctl.conf

echo ""
echo ""

#DOCKER
$a apt-get install ca-certificates curl gnupg -y
$a install -m 0755 -d /etc/apt/keyrings
$a curl -fsSL https://download.docker.com/linux/debian/gpg | $a gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$a chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | $a tee /etc/apt/sources.list.d/docker.list > /dev/null
$a apt-get update
$a apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
#FAIL2BAN
