#!/bin/bash
### give it random number to serverid on MariaDB
# To generate a random number in a UNIX or Linux shell, the shell maintains a shell variable named RANDOM. Each time this variable is read, a random number between 0 and 32767 is generated.
SERVERID=$(($RANDOM))
GTID=$(($RANDOM))
##### Checking MariaDB Version #####
MARIADB_VERSION=`mysql --version |awk -F "-" {'print $1'}|awk -F "." {'print $1$2$3'} | awk {'print $5'}`

### get amount of memory who will be reserved to InnoDB Buffer Pool
INNODB_MEM=$(expr $(($(cat /proc/meminfo | grep MemTotal | awk '{print $2}') / 10)) \* 7 / 1024)M

### get the number of cpu's to estimate how many innodb instances will be enough for it. ###
NR_CPUS=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)

if [[ $NR_CPUS -gt 8 ]]
then
 INNODB_INSTANCES=$NR_CPUS
 INNODB_WRITES=16
 INNODB_READS=16
 INNODB_MIN_IO=200
 INNODB_MAX_IO=800
 TEMP_TABLE_SIZE='16M'
 NR_CONNECTIONS=1000
 NR_CONNECTIONS_USER=950
 SORT_MEM='256M'
 SORT_BLOCK="read_rnd_buffer_size                    = 1M
read_buffer_size                        = 1M
max_sort_length                         = 1M
max_length_for_sort_data                = 1M
mrr_buffer_size                         = 1M
group_concat_max_len                    = 4096"
else
 INNODB_INSTANCES=8
 INNODB_WRITES=8
 INNODB_READS=8
 INNODB_MIN_IO=200
 INNODB_MAX_IO=300
 TEMP_TABLE_SIZE='16M'
 NR_CONNECTIONS=500
 NR_CONNECTIONS_USER=450
 SORT_MEM='128M'
 SORT_BLOCK="read_rnd_buffer_size                    = 131072
max_sort_length                         = 262144
max_length_for_sort_data                = 262144
read_buffer_size                        = 131072
mrr_buffer_size                         = 131072
group_concat_max_len                    = 2048"
fi

### datadir and logdir ####
DATA_DIR="/var/lib/mysql/datadir"
DATA_LOG="/var/lib/mysql-logs"
TMP_DIR="/var/lib/mysql-tmp"

if [ "$MARIADB_VERSION" == "101" ]; then
  ### collation and character set ###
  COLLATION="utf8_general_ci"
  CHARACTERSET="utf8"
  MARIADB_BLOCK='innodb_large_prefix                     = 1'
elif [[ "$MARIADB_VERSION" == "102" ]]; then
  ### collation and character set ###
  COLLATION="utf8_general_ci"
  CHARACTERSET="utf8"
  MARIADB_BLOCK='innodb_large_prefix                     = 1'
elif [[ "$MARIADB_VERSION" == "103" ]]; then
  ### collation and character set ###
  COLLATION="utf8mb4_general_ci"
  CHARACTERSET="utf8mb4"
  MARIADB_BLOCK='######'
elif [[ "$MARIADB_VERSION" == "104" ]]; then
  ### collation and character set ###
  COLLATION="utf8mb4_general_ci"
  CHARACTERSET="utf8mb4"
  MARIADB_BLOCK='######'
fi

echo "[client]
port                                    = 3306
socket                                  = /var/lib/mysql/mysql.sock

[mysqld]
server-id                               = $SERVERID
gtid_domain_id                          = $GTID
sql_mode                                = 'NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'
port                                    = 3306
pid-file                                = /var/lib/mysql/mysql.pid
socket                                  = /var/lib/mysql/mysql.sock
basedir                                 = /usr
local_infile                            = 1

# general configs
datadir                                 = $DATA_DIR
collation-server                        = $COLLATION
character_set_server                    = $CHARACTERSET
init-connect                            = SET NAMES $CHARACTERSET
lower_case_table_names                  = 1
default-storage-engine                  = InnoDB
optimizer_switch                        = 'index_merge_intersection=off'
bulk_insert_buffer_size                 = 128M

# files limits
open_files_limit                        = 102400
innodb_open_files                       = 65536

query_cache_size                        = 0
query_cache_type                        = 0

thread_handling                         = pool-of-threads
thread_cache_size                       = 300

# logbin configs
log-bin                                 = $DATA_LOG/mysql-bin
binlog_format                           = ROW
binlog_checksum                         = CRC32
expire_logs_days                        = 5
log_bin_trust_function_creators         = 1
sync_binlog                             = 1
log_slave_updates                       = 1

relay_log                               = $DATA_LOG/mysql-relay-bin
relay_log_purge                         = 1

# slave configs
slave_compressed_protocol               = 1
slave_ddl_exec_mode                     = IDEMPOTENT
slave_net_timeout                       = 60
slave_parallel_threads                  = 0
slave_sql_verify_checksum               = ON

# innodb vars
innodb_buffer_pool_size                 = $INNODB_MEM
innodb_buffer_pool_instances            = $INNODB_INSTANCES
innodb_flush_log_at_trx_commit          = 1
innodb_file_per_table                   = 1
innodb_flush_method                     = O_DIRECT
innodb_flush_neighbors                  = 0
innodb_log_buffer_size                  = 16M
innodb_lru_scan_depth                   = 4096
innodb_purge_threads                    = 4
innodb_sync_array_size                  = 4
innodb_autoinc_lock_mode                = 2
innodb_print_all_deadlocks              = 1
innodb_io_capacity                      = $INNODB_MIN_IO
innodb_io_capacity_max                  = $INNODB_MAX_IO
innodb_read_io_threads                  = $INNODB_READS
innodb_write_io_threads                 = $INNODB_WRITES
innodb_max_dirty_pages_pct              = 90
innodb_max_dirty_pages_pct_lwm          = 10
innodb_doublewrite                      = 1
innodb_thread_concurrency               = 0
$MARIADB_BLOCK

# innodb redologs
innodb_log_file_size                    = 1G
innodb_log_files_in_group               = 4

# table configs
table_open_cache                        = 16384
table_definition_cache                  = 52428
max_heap_table_size                     = $TEMP_TABLE_SIZE
tmp_table_size                          = $TEMP_TABLE_SIZE
tmpdir                                  = $TMP_DIR

# connection configs
max_allowed_packet                      = 1G
net_buffer_length                       = 999424
max_connections                         = $NR_CONNECTIONS
max_connect_errors                      = 100
wait_timeout                            = 28800
connect_timeout                         = 60
skip-name-resolve                       = 1

# sort and group configs
key_buffer_size                         = 32M
sort_buffer_size                        = $SORT_MEM
innodb_sort_buffer_size                 = 67108864
myisam_sort_buffer_size                 = $SORT_MEM
join_buffer_size                        = $SORT_MEM
$SORT_BLOCK

# log configs
slow_query_log                          = 1
slow_query_log_file                     = $DATA_LOG/mysql-slow.log
long_query_time                         = 0
log_slow_verbosity                      = query_plan,explain
log_slow_admin_statements               = ON
log_slow_slave_statements               = ON
log_queries_not_using_indexes           = ON

log-error                               = $DATA_LOG/mysql-error.log

general_log_file                        = $DATA_LOG/mysql-general.log
general_log                             = 0

# enable scheduler on MariaDB
event_scheduler                         = 1

# Performance monitoring (with low overhead)
innodb_monitor_enable                   = all
performance_schema                      = OFF
performance-schema-instrument           ='%=ON'
performance-schema-consumer-events-stages-current=ON
performance-schema-consumer-events-stages-history=ON
performance-schema-consumer-events-stages-history-long=ON
" > /etc/my.cnf.d/server.cnf

### restart mysql service to apply new config file generate in this stage ###
#killall mysqld
pid_mysql=$(pidof mysqld)
if [[ $pid_mysql -gt 1 ]]
then
kill -15 $pid_mysql
fi
sleep 10

# clean standard mysql dir
rm -rf /var/lib/mysql/*
chown -R mysql:mysql /var/lib/mysql
### remove old config file ####
rm -rf /root/.my.cnf

# create directories for mysql datadir and datalog
if [ ! -d ${DATA_DIR} ]
then
    mkdir -p ${DATA_DIR}
    chmod 755 ${DATA_DIR}
    chown -Rf mysql.mysql ${DATA_DIR}
else
    chown -Rf mysql.mysql ${DATA_DIR}
fi

if [ ! -d ${DATA_LOG} ]
then
    mkdir -p ${DATA_LOG}
    chmod 755 ${DATA_LOG}
    chown -Rf mysql.mysql ${DATA_LOG}
else
    chown -Rf mysql.mysql ${DATA_LOG}
fi

if [ ! -d ${TMP_DIR} ]
then
    mkdir -p ${TMP_DIR}
    chmod 755 ${TMP_DIR}
    chown -Rf mysql.mysql ${TMP_DIR}
else
    chown -Rf mysql.mysql ${TMP_DIR}
fi


### mysql_install_db for deploy a new db fresh and clean ###
mysql_install_db --user=mysql --skip-name-resolve --force --defaults-file=/etc/my.cnf.d/server.cnf
sleep 5

### start mysql service ###
systemctl enable mariadb.service
sleep 5
systemctl start mariadb.service
sleep 5

### standalone instance standard users ##
REPLICATION_USER_NAME="replication_user"
MYSQLCHK_USER_NAME="mysqlchk"

### generate mysqlchk passwd #####
RD_MYSQLCHK_USER_PWD="mysqlchk-$SERVERID-$GTID"
touch /tmp/$RD_MYSQLCHK_USER_PWD
echo $RD_MYSQLCHK_USER_PWD > /tmp/$RD_MYSQLCHK_USER_PWD
HASH_MYSQLCHK_USER_PWD=`md5sum  /tmp/$RD_MYSQLCHK_USER_PWD | awk '{print $1}' | sed -e 's/^[[:space:]]*//' | tr -d '/"/'`

### generate replication passwd #####
RD_REPLICATION_USER_PWD="replication-$SERVERID-$GTID"
touch /tmp/$RD_REPLICATION_USER_PWD
echo $RD_REPLICATION_USER_PWD > /tmp/$RD_REPLICATION_USER_PWD
HASH_REPLICATION_USER_PWD=`md5sum  /tmp/$RD_REPLICATION_USER_PWD | awk '{print $1}' | sed -e 's/^[[:space:]]*//' | tr -d '/"/'`

### users pwd ##
MYSQLCHK_USER_PWD=$HASH_MYSQLCHK_USER_PWD
REPLICATION_USER_PWD=$HASH_REPLICATION_USER_PWD

### generate root passwd #####
passwd="root-$SERVERID-$GTID"
touch /tmp/$passwd
echo $passwd > /tmp/$passwd
hash=`md5sum  /tmp/$passwd | awk '{print $1}' | sed -e 's/^[[:space:]]*//' | tr -d '/"/'`

### update root password #####
mysqladmin -u root password $hash

### show users and pwds ####
echo The server_id is $SERVERID and the gt_domain_id is $GTID!
echo The root password is $hash
echo The $REPLICATION_USER_NAME password is $REPLICATION_USER_PWD
echo The $MYSQLCHK_USER_NAME password is $MYSQLCHK_USER_PWD

### generate it the user file on root account linux #####
echo "[client]
user            = root
password        = $hash

[mysql]
user            = root
password        = $hash
prompt          = '(\u@\h) MariaDB [\d]>\_'

[mysqladmin]
user            = root
password        = $hash

[mysqldump]
user            = root
password        = $hash

###### Automated users generated by the installation process ####
#The root password is $hash
#The $REPLICATION_USER_NAME password is $REPLICATION_USER_PWD
#The $MYSQLCHK_USER_NAME password is $MYSQLCHK_USER_PWD
#################################################################
" > /root/.my.cnf

### setup the users for monitoring/replication streaming and security purpose ###
mysql -e "GRANT REPLICATION SLAVE ON *.* TO '$REPLICATION_USER_NAME'@'%' IDENTIFIED BY '$REPLICATION_USER_PWD';";
mysql -e "GRANT PROCESS ON *.* TO '$MYSQLCHK_USER_NAME'@'localhost' IDENTIFIED BY '$MYSQLCHK_USER_PWD';";
mysql -e "DELETE FROM mysql.user WHERE User='';";
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "UPDATE mysql.user SET Password=PASSWORD('$hash') WHERE User='root';"
mysql -e "flush privileges;"

### REMOVE TMP FILES on /tmp #####
rm -rf /tmp/*
