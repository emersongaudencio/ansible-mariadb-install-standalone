#!/bin/bash
echo "HOSTNAME: " `hostname`
echo "BEGIN - [`date +%d/%m/%Y" "%H:%M:%S`]"
echo "##############"
echo "$1" > /tmp/MARIADB_VERSION
MARIADB_VERSION=$(cat /tmp/MARIADB_VERSION)

# os_type = rhel
os_type=
# os_version as demanded by the OS (codename, major release, etc.)
os_version=
supported="Only RHEL/CentOS 7 & 8 are supported for this installation process."

msg(){
    type=$1 #${1^^}
    shift
    printf "[$type] %s\n" "$@" >&2
}

error(){
    msg error "$@"
    exit 1
}

identify_os(){
    arch=$(uname -m)
    # Check for RHEL/CentOS, Fedora, etc.
    if command -v rpm >/dev/null && [[ -e /etc/redhat-release || -e /etc/os-release ]]
    then
        os_type=rhel
        el_version=$(rpm -qa '(oraclelinux|sl|redhat|centos|fedora|rocky|alma|system)*release(|-server)' --queryformat '%{VERSION}')
        case $el_version in
            1*) os_version=6 ; error "RHEL/CentOS 6 is no longer supported" "$supported" ;;
            2*) os_version=7 ;;
            5*) os_version=5 ; error "RHEL/CentOS 5 is no longer supported" "$supported" ;;
            6*) os_version=6 ; error "RHEL/CentOS 6 is no longer supported" "$supported" ;;
            7*) os_version=7 ;;
            8*) os_version=8 ;;
             *) error "Detected RHEL or compatible but version ($el_version) is not supported." "$supported"  "$otherplatforms" ;;
         esac
         if [[ $arch == aarch64 ]] && [[ $os_version != 7 ]]; then error "Only RHEL/CentOS 7 are supported for ARM64. Detected version: '$os_version'"; fi
    fi

    if ! [[ $os_type ]] || ! [[ $os_version ]]
    then
        error "Could not identify OS type or version." "$supported"
    fi
}

### OS auto discovey to identify which is the OS and version thats been used it.
identify_os

echo $os_type
echo $os_version

##### FIREWALLD DISABLE ########################
systemctl disable firewalld
systemctl stop firewalld
######### SELINUX ###############################
sed -ie 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
# disable selinux on the fly
/usr/sbin/setenforce 0

### clean yum cache ###
rm -rf /etc/yum.repos.d/MariaDB.repo
rm -rf /etc/yum.repos.d/mariadb.repo
rm -rf /etc/yum.repos.d/mysql-community.repo
rm -rf /etc/yum.repos.d/mysql-community-source.repo
rm -rf /etc/yum.repos.d/percona-original-release.repo
yum clean all

if [ "$MARIADB_VERSION" == "101" ]; then
   VERSION="10.1"
elif [[ "$MARIADB_VERSION" == "102" ]]; then
   VERSION="10.2"
elif [[ "$MARIADB_VERSION" == "103" ]]; then
   VERSION="10.3"
elif [[ "$MARIADB_VERSION" == "104" ]]; then
   VERSION="10.4"
elif [[ "$MARIADB_VERSION" == "105" ]]; then
   VERSION="10.5"
elif [[ "$MARIADB_VERSION" == "106" ]]; then
  VERSION="10.6"
elif [[ "$MARIADB_VERSION" == "107" ]]; then
  VERSION="10.7"
elif [[ "$MARIADB_VERSION" == "108" ]]; then
  VERSION="10.8"
elif [[ "$MARIADB_VERSION" == "109" ]]; then
  VERSION="10.9"
fi

####### PACKAGES ###########################
if [[ $os_type == "rhel" ]]; then
    if [[ $os_version == "7" ]]; then
      # -------------- For RHEL/CentOS 7 --------------
      yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
      #### REPO MARIADB ######
      # -------------- For RHEL/CentOS 7 --------------
      echo "# MariaDB $VERSION CentOS repository list
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/$VERSION/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1" > /etc/yum.repos.d/mariadb.repo
    elif [[ $os_version == "8" ]]; then
      # -------------- For RHEL/CentOS 8 --------------
      yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
      #### REPO MARIADB ######
      # -------------- For RHEL/CentOS 8 --------------
      echo "# MariaDB $VERSION CentOS repository list
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/$VERSION/centos8-amd64
module_hotfixes=1
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1" > /etc/yum.repos.d/mariadb.repo
    fi
# yum -y install epel-release
fi

### remove old packages ####
yum -y remove mariadb-libs
yum -y remove 'maria*'
yum -y remove mysql mysql-server mysql-libs mysql-common mysql-community-common mysql-community-libs
yum -y remove 'mysql*'
yum -y remove MariaDB-common MariaDB-compat
yum -y remove MariaDB-server MariaDB-client
yum -y remove percona-release
yum -y remove galera

### clean yum cache ###
yum clean all

### monitoring pre-packages ####
yum -y install nload bmon iptraf glances nmap htop dstat sysstat socat

# dev tools
yum -y install screen yum-utils expect perl perl-DBI perl-IO-Socket-SSL perl-Digest-MD5 perl-TermReadKey  libev gcc zlib zlib-devel openssl openssl-devel python3 python3-pip python3-devel

# others pre-packages
yum -y install pigz zlib file sudo libaio rsync snappy net-tools wget

### clean yum cache ###
yum clean all

### Installation MARIADB via yum ####
yum -y install MariaDB-client
yum -y install MariaDB-server
yum -y install MariaDB-compat
yum -y install perl-DBD-MySQL
yum -y install MySQL-python
yum -y install MariaDB-backup


####### PACKAGES ###########################
if [[ $os_type == "rhel" ]]; then
    if [[ $os_version == "7" ]]; then
      # -------------- For RHEL/CentOS 7 --------------
      #### mydumper ######
      yum -y install https://github.com/mydumper/mydumper/releases/download/v0.11.5-2/mydumper-0.11.5-2.el7.x86_64.rpm

      #### qpress #####
      #yum -y install https://github.com/emersongaudencio/linux_packages/raw/master/RPM/qpress-11-1.el7.x86_64.rpm
      yum -y install https://repo.percona.com/tools/yum/release/7/RPMS/x86_64/qpress-11-1.el7.x86_64.rpm
    elif [[ $os_version == "8" ]]; then
      #### mydumper ######
      yum -y install https://github.com/mydumper/mydumper/releases/download/v0.11.5-2/mydumper-0.11.5-2.el8.x86_64.rpm

      #### qpress #####
      #yum -y install https://github.com/emersongaudencio/linux_packages/raw/master/RPM/qpress-11-1.el8.x86_64.rpm
      yum -y install https://repo.percona.com/tools/yum/release/8/RPMS/x86_64/qpress-11-1.el8.x86_64.rpm
    fi
fi

### Percona #####
### https://www.percona.com/doc/percona-server/LATEST/installation/yum_repo.html
yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm -y
yum -y install percona-toolkit sysbench

### installation mysql add-ons via yum ####
yum -y install perl-DBD-MySQL
yum -y install jemalloc

#####  MYSQL LIMITS ###########################
check_limits=$(cat /etc/security/limits.conf | grep '# mysql-pre-reqs' | wc -l)
if [ "$check_limits" == "0" ]; then
echo ' ' >> /etc/security/limits.conf
echo '# mysql-pre-reqs' >> /etc/security/limits.conf
echo 'mysql              soft    nproc   102400' >> /etc/security/limits.conf
echo 'mysql              hard    nproc   102400' >> /etc/security/limits.conf
echo 'mysql              soft    nofile  102400' >> /etc/security/limits.conf
echo 'mysql              hard    nofile  102400' >> /etc/security/limits.conf
echo 'mysql              soft    stack   102400' >> /etc/security/limits.conf
echo 'mysql              soft    core unlimited' >> /etc/security/limits.conf
echo 'mysql              hard    core unlimited' >> /etc/security/limits.conf
echo '# all_users' >> /etc/security/limits.conf
echo '* soft nofile 102400' >> /etc/security/limits.conf
echo '* hard nofile 102400' >> /etc/security/limits.conf
else
echo "MySQL Pre-reqs for /etc/security/limits.conf is already in place!"
fi

##### CONFIG PROFILE #############
check_profile=$(cat /etc/profile | grep '# mysql-pre-reqs' | wc -l)
if [ "$check_profile" == "0" ]; then
echo ' ' >> /etc/profile
echo '# mysql-pre-reqs' >> /etc/profile
echo 'if [ $USER = "mysql" ]; then' >> /etc/profile
echo '  if [ $SHELL = "/bin/bash" ]; then' >> /etc/profile
echo '    ulimit -u 65536 -n 65536' >> /etc/profile
echo '  else' >> /etc/profile
echo '    ulimit -u 65536 -n 65536' >> /etc/profile
echo '  fi' >> /etc/profile
echo 'fi' >> /etc/profile
else
echo "MySQL Pre-reqs for /etc/profile is already in place!"
fi

##### SYSCTL MARIADB/MYSQL ###########################
check_sysctl=$(cat /etc/sysctl.conf | grep '# mysql-pre-reqs' | wc -l)
if [ "$check_sysctl" == "0" ]; then
# insert parameters into /etc/sysctl.conf for incresing MariaDB limits
echo "# mysql-pre-reqs
# virtual memory limits
vm.swappiness = 1
vm.dirty_background_ratio = 3
vm.dirty_ratio = 40
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
fs.suid_dumpable = 1
vm.nr_hugepages = 0
# file system limits
fs.aio-max-nr = 1048576
fs.file-max = 6815744
# kernel limits
kernel.panic_on_oops = 1
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.shmmni = 4096
# kernel semaphores: semmsl, semmns, semopm, semmni
kernel.sem = 250 32000 100 128
# networking limits
net.ipv4.ip_local_port_range = 9000 65499
net.core.rmem_default=4194304
net.core.rmem_max=4194304
net.core.wmem_default=262144
net.core.wmem_max=1048586" >> /etc/sysctl.conf
else
echo "MySQL Pre-reqs for /etc/sysctl.conf is already in place!"
fi
# reload confs of /etc/sysctl.confs
sysctl -p

#####  MARIADB/MYSQL LIMITS ###########################
mkdir -p /etc/systemd/system/mariadb.service.d/
echo '[Service]' > /etc/systemd/system/mariadb.service.d/limits.conf
echo 'LimitNOFILE=102400' >> /etc/systemd/system/mariadb.service.d/limits.conf
echo '[Service]' > /etc/systemd/system/mariadb.service.d/timeout.conf
echo 'TimeoutSec=28800' >> /etc/systemd/system/mariadb.service.d/timeout.conf
mkdir -p /etc/systemd/system/mysqld.service.d/
echo '[Service]' > /etc/systemd/system/mysqld.service.d/limits.conf
echo 'LimitNOFILE=102400' >> /etc/systemd/system/mysqld.service.d/limits.conf
echo '[Service]' > /etc/systemd/system/mysqld.service.d/timeout.conf
echo 'TimeoutSec=28800' >> /etc/systemd/system/mysqld.service.d/timeout.conf
systemctl daemon-reload

#####  MYSQL MEMORY ALLOCATOR ###########################
echo '[Service]' > /etc/systemd/system/mariadb.service.d/malloc.conf
echo 'ExecStartPre=/bin/sh -c "systemctl unset-environment LD_PRELOAD"' >> /etc/systemd/system/mariadb.service.d/malloc.conf
echo 'ExecStartPre=/bin/sh -c "systemctl set-environment LD_PRELOAD=/usr/lib64/libjemalloc.so.1"' >> /etc/systemd/system/mariadb.service.d/malloc.conf
echo '[Service]' > /etc/systemd/system/mysqld.service.d/malloc.conf
echo 'ExecStartPre=/bin/sh -c "systemctl unset-environment LD_PRELOAD"' >> /etc/systemd/system/mysqld.service.d/malloc.conf
echo 'ExecStartPre=/bin/sh -c "systemctl set-environment LD_PRELOAD=/usr/lib64/libjemalloc.so.1"' >> /etc/systemd/system/mysqld.service.d/malloc.conf
systemctl daemon-reload

# disable transparent huge pages
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.d/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
  echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi

### REMOVE MARIADB VERSION FILE #####
rm -rf /tmp/MARIADB_VERSION

echo "##############"
echo "END - [`date +%d/%m/%Y" "%H:%M:%S`]"
