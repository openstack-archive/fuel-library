#!/bin/bash
#    Copyright 2016 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

function retry_checker {
    tries=0
    echo "checking with command \"$*\""
    until eval $*; do
        rc=$?
        let 'tries=tries+1'
        echo "try number $tries"
        echo "return code is $rc"
        if [ $tries -gt $CHECK_RETRIES ];then
            failure=1
            break
        fi
     sleep 5
  done
}

function get_service_credentials {
  credentialfile=$(mktemp /tmp/servicepws.XXXXX)
  flat_yaml.py $ASTUTE_YAML > $credentialfile
  . $credentialfile
  rm -f $credentialfile
}

function check_ready {
  #Uses a custom command to ensure a container is ready
  get_service_credentials
  failure=0

  case $1 in
      nailgun)
          if [ "${SYSTEMD:-false}" == "true" ]; then
              retry_checker "systemctl is-active nailgun"
          else
              retry_checker "supervisorctl status nailgun | grep -q RUNNING"
          fi
          ;;
      ostf)
          retry_checker "egrep -q ^[2-4][0-9]? < <(curl --connect-timeout 1 -s -w '%{http_code}' http://$ADMIN_IP:8777/ostf/not_found -o /dev/null)"
          ;;
      #NOTICE: Cobbler console tool does not comply unix conversation: 'cobbler profile find' always return 0 as exit code
      cobbler)
          retry_checker "ps waux | grep -q 'cobblerd -F' && pgrep dnsmasq"
          retry_checker "cobbler profile find --name=centos* | grep -q centos && cobbler profile find --name=ubuntu* | grep -q ubuntu && cobbler profile find --name=bootstrap* | grep -q bootstrap"
          ;;
      rabbitmq)
          retry_checker "curl -f -L -i  -u \"$astute_user:$astute_password\" http://$ADMIN_IP:15672/api/nodes  1>/dev/null 2>&1"
          retry_checker "curl -f -L -u \"$mcollective_user:$mcollective_password\" -s http://$ADMIN_IP:15672/api/exchanges | grep -qw 'mcollective_broadcast'"
          retry_checker "curl -f -L -u \"$mcollective_user:$mcollective_password\" -s http://$ADMIN_IP:15672/api/exchanges | grep -qw 'mcollective_directed'"
          ;;
      postgres)
          retry_checker "PGPASSWORD=$postgres_nailgun_password /usr/bin/psql -h $ADMIN_IP -U \"$postgres_nailgun_user\" \"$postgres_nailgun_dbname\" -c '\copyright' 2>&1 1>/dev/null"
          ;;
      astute)
          retry_checker "ps waux | grep -q 'astuted'"
          retry_checker "curl -f -L -u \"$astute_user:$astute_password\" -s http://$ADMIN_IP:15672/api/exchanges | grep -qw 'nailgun'"
          retry_checker "curl -f -L -u \"$astute_user:$astute_password\" -s http://$ADMIN_IP:15672/api/exchanges | grep -qw 'naily_service'"
          ;;
      rsync)
          retry_checker "netstat -ntl | grep -q 873"
          ;;
      rsyslog)
          retry_checker "netstat -nl | grep -q 514"
          ;;
      mcollective)
          retry_checker "ps waux | grep -q mcollectived"
          ;;
      nginx)
          retry_checker "ps waux | grep -q nginx"
          ;;
      keystone)
          retry_checker "keystone  --os-auth-url \"http://$ADMIN_IP:35357/v2.0\" --os-username \"$keystone_nailgun_user\" --os-password \"$keystone_nailgun_password\" token-get &>/dev/null"
          ;;
      *)
          echo "No defined test for determining if $1 is ready."
          ;;
  esac

  #Catch all to ensure puppet is not running
  retry_checker "! pgrep puppet"

  if [ $failure -eq 1 ]; then
    echo "ERROR: $1 failed to start."
    return 1
  else
    echo "$1 is ready."
    return 0
  fi
}
