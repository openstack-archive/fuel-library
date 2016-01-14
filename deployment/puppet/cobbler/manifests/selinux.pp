#    Copyright 2013 Mirantis, Inc.
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


class cobbler::selinux {
  if !$::selinux {

    Exec { path => '/usr/bin:/bin:/usr/sbin:/sbin' }

    exec { 'cobbler_disable_selinux':
      command => 'setenforce 0',
      onlyif  => 'getenforce | grep -q Enforcing',
    }

    exec { 'cobbler_disable_selinux_permanent':
      command => 'sed -ie "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config',
      onlyif  => 'grep -q "^SELINUX=enforcing" /etc/selinux/config'
    }

  }
}
