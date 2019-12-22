#!/bin/bash

export SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PYTHON_BIN=/usr/bin/python
export ANSIBLE_CONFIG=$SCRIPT_PATH/ansible/ansible.cfg

cd $SCRIPT_PATH

# Variables (Options) defined in here
VAR_MARIADB_VERSION="101"

ansible-playbook -vvv -i $SCRIPT_PATH/ansible/hosts  -e "{mariadb_version: '$VAR_MARIADB_VERSION'}" $SCRIPT_PATH/ansible/playbook/mariadb_install.yml
exit $?
