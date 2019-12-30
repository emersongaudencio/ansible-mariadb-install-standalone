#!/bin/bash

export SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export PYTHON_BIN=/usr/bin/python
export ANSIBLE_CONFIG=$SCRIPT_PATH/ansible.cfg

cd $SCRIPT_PATH

VAR_MARIADB_HOST="dbtest02"
VAR_SSH_USER="master"
VAR_MARIADB_VERSION="103"

### Ping host ####
ansible -i $SCRIPT_PATH/hosts -m ping $VAR_MARIADB_HOST -u $VAR_SSH_USER -o

### MariaDB install ####
ansible-playbook -v -i $SCRIPT_PATH/hosts -e "{mariadb_version: '$VAR_MARIADB_VERSION'}" $SCRIPT_PATH/playbook/mariadb_install.yml -l $VAR_MARIADB_HOST  -u $VAR_SSH_USER
