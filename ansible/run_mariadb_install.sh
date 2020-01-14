#!/bin/bash

export SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export PYTHON_BIN=/usr/bin/python
export ANSIBLE_CONFIG=$SCRIPT_PATH/ansible.cfg

cd $SCRIPT_PATH

VAR_HOST="$1"
VAR_MARIADB_VERSION="$2"

if [ "${VAR_HOST}" == '' ] ; then
  echo "No host specified. Please have a look at README file for futher information!"
  exit 1
fi

if [ "${VAR_MARIADB_VERSION}" == '' ] ; then
  echo "No MariaDB version specified. Please have a look at README file for futher information!"
  exit 1
fi

if [ "$VAR_MARIADB_VERSION" -gt 0 -a "$VAR_HOST" != "" ]; then
  ### Ping host ####
  ansible -i $SCRIPT_PATH/hosts -m ping $VAR_HOST -v

  ### MariaDB install ####
  ansible-playbook -v -i $SCRIPT_PATH/hosts -e "{mariadb_version: '$VAR_MARIADB_VERSION'}" $SCRIPT_PATH/playbook/mariadb_install.yml -l $VAR_HOST
else
  echo "Sorry, this script must have 2 parameters to run. So first of all you have to fill up the first parameter with the ansible hostname and the second parameter MariaDB version, please have a look at README file for futher information!"
  exit 1
fi
