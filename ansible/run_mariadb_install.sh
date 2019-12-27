#!/bin/bash

export SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PYTHON_BIN=/usr/bin/python
export ANSIBLE_CONFIG=$SCRIPT_PATH/ansible/ansible.cfg

cd $SCRIPT_PATH

# Variables (Options) defined in here
VAR_MARIADB_VERSION="$1"
VAR_MARIADB_HOST="$2"
VAR_SSH_USER="$3"

### Ping host #####
ansible -m ping $VAR_MARIADB_HOST -u $VAR_SSH_USER --ask-pass --become -v
### Ping host - using private key #####
# ansible -m ping $VAR_MARIADB_HOST -u $VAR_SSH_USER --private-key=/root/keys/private_key.pem --become -v

### mysql install ####
ansible-playbook -v -i $SCRIPT_PATH/ansible/hosts -e "{mariadb_version: '$VAR_MARIADB_VERSION'}" $SCRIPT_PATH/ansible/playbook/mariadb_install.yml -l $VAR_MARIADB_HOST  -u $VAR_SSH_USER --ask-pass --become
### mysql install - using private key ####
# ansible-playbook -v -i $SCRIPT_PATH/ansible/hosts -e "{mariadb_version: '$VAR_MARIADB_VERSION'}" $SCRIPT_PATH/ansible/playbook/mariadb_install.yml -l $VAR_MARIADB_HOST  -u $VAR_SSH_USER --private-key=/root/keys/private_key.pem --become

exit $?
