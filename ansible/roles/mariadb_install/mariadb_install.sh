#!/bin/sh
echo "HOSTNAME: " `hostname`
echo "BEGIN - [`date +%d/%m/%Y" "%H:%M:%S`]"
echo "##############"
MARIADB_VERSION=$(cat /tmp/MARIADB_VERSION)

##### FIREWALLD DISABLE ########################
systemctl disable firewalld
systemctl stop firewalld
######### SELINUX ###############################
sed -ie 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
# disable selinux on the fly
/usr/sbin/setenforce 0

### Clean yum cache ###
rm -rf /etc/yum.repos.d/MariaDB.repo
rm -rf /etc/yum.repos.d/mariadb.repo
yum clean headers
yum clean packages
yum clean metadata

####### PACKAGES ###########################
# -------------- For RHEL/CentOS 7 --------------
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install epel-release

### remove old packages ####
yum -y remove mariadb-libs
yum -y remove 'maria*'
yum -y remove mysql mysql-server mysql-libs mysql-common mysql-community-common mysql-community-libs
yum -y remove 'mysql*'
yum -y remove MariaDB-common MariaDB-compat
yum -y remove MariaDB-server MariaDB-client

### install pre-packages ####
yum -y install screen expect nload bmon iptraf glances perl perl-DBI openssl pigz zlib file sudo  libaio rsync snappy net-tools wget nmap htop dstat sysstat perl-IO-Socket-SSL perl-Digest-MD5 perl-TermReadKey socat libev gcc zlib zlib-devel openssl openssl-devel python-pip python-devel

if [ "$MARIADB_VERSION" == "101" ]; then
   VERSION="10.1"
elif [[ "$MARIADB_VERSION" == "102" ]]; then
   VERSION="10.2"
elif [[ "$MARIADB_VERSION" == "103" ]]; then
   VERSION="10.3"
elif [[ "$MARIADB_VERSION" == "104" ]]; then
   VERSION="10.4"
fi

#### REPO MARIADB ######
# -------------- For RHEL/CentOS 7 --------------
echo "# MariaDB $VERSION CentOS repository list
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/$VERSION/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1" > /etc/yum.repos.d/mariadb.repo

### clean yum cache ###
yum clean headers
yum clean packages
yum clean metadata

### installation maridb via yum ####
yum -y install MariaDB-server MariaDB-client
yum -y install perl-DBD-MySQL  MySQL-python

#### mydumper ######
yum -y install https://github.com/maxbube/mydumper/releases/download/v0.9.5/mydumper-0.9.5-2.el7.x86_64.rpm

### Percona #####
### https://www.percona.com/doc/percona-server/LATEST/installation/yum_repo.html
yum install https://repo.percona.com/yum/release/7/RPMS/x86_64/qpress-11-1.el7.x86_64.rpm -y
yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm -y
yum -y install percona-toolkit
yum -y install MariaDB-backup

##### SYSCTL MYSQL ###########################
# insert parameters into /etc/sysctl.conf for incresing MariaDB limits
echo "# mysql preps
vm.swappiness = 0
fs.suid_dumpable = 1
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.shmmni = 4096
# semaphores: semmsl, semmns, semopm, semmni
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default=4194304
net.core.rmem_max=4194304
net.core.wmem_default=262144
net.core.wmem_max=1048586" > /etc/sysctl.conf

# recarrega confs do /etc/sysctl.conf
sysctl -p

#####  MYSQL LIMITS ###########################

echo ' ' >> /etc/security/limits.conf
echo '# mysql' >> /etc/security/limits.conf
echo 'mysql              soft    nproc   2047' >> /etc/security/limits.conf
echo 'mysql              hard    nproc   16384' >> /etc/security/limits.conf
echo 'mysql              soft    nofile  4096' >> /etc/security/limits.conf
echo 'mysql              hard    nofile  65536' >> /etc/security/limits.conf
echo 'mysql              soft    stack   10240' >> /etc/security/limits.conf
echo '# all_users' >> /etc/security/limits.conf
echo '* soft nofile 102400' >> /etc/security/limits.conf
echo '* hard nofile 102400' >> /etc/security/limits.conf

#####  MYSQL LIMITS ###########################
mkdir -p /etc/systemd/system/mariadb.service.d/
echo ' ' > /etc/systemd/system/mariadb.service.d/limits.conf
echo '# mysql' >> /etc/systemd/system/mariadb.service.d/limits.conf
echo '[Service]' >> /etc/systemd/system/mariadb.service.d/limits.conf
echo 'LimitNOFILE=102400' >> /etc/systemd/system/mariadb.service.d/limits.conf
echo ' ' > /etc/systemd/system/mariadb.service.d/timeout.conf
echo '# mysql' >> /etc/systemd/system/mariadb.service.d/timeout.conf
echo '[Service]' >> /etc/systemd/system/mariadb.service.d/timeout.conf
echo 'TimeoutSec=28800' >> /etc/systemd/system/mariadb.service.d/timeout.conf
mkdir -p /etc/systemd/system/mysqld.service.d/
echo ' ' > /etc/systemd/system/mysqld.service.d/limits.conf
echo '# mysql' >> /etc/systemd/system/mysqld.service.d/limits.conf
echo '[Service]' >> /etc/systemd/system/mysqld.service.d/limits.conf
echo 'LimitNOFILE=102400' >> /etc/systemd/system/mysqld.service.d/limits.conf
echo ' ' > /etc/systemd/system/mysqld.service.d/timeout.conf
echo '# mysql' >> /etc/systemd/system/mysqld.service.d/timeout.conf
echo '[Service]' >> /etc/systemd/system/mysqld.service.d/timeout.conf
echo 'TimeoutSec=28800' >> /etc/systemd/system/mysqld.service.d/timeout.conf
systemctl daemon-reload

##### CONFIG PROFILE #############
echo ' ' >> /etc/profile
echo '# mysql' >> /etc/profile
echo 'if [ $USER = "mysql" ]; then' >> /etc/profile
echo '  if [ $SHELL = "/bin/bash" ]; then' >> /etc/profile
echo '    ulimit -u 16384 -n 65536' >> /etc/profile
echo '  else' >> /etc/profile
echo '    ulimit -u 16384 -n 65536' >> /etc/profile
echo '  fi' >> /etc/profile
echo 'fi' >> /etc/profile

echo "##############"
echo "END - [`date +%d/%m/%Y" "%H:%M:%S`]"
