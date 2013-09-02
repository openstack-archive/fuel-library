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


class cobbler::checksum_bootpc () {
  
  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}
  
  case $operatingsystem {
    /(?i)(centos|redhat)/ : {
      exec { "checksum_fill_bootpc":
        command => "iptables -t mangle -A POSTROUTING -p udp --dport 68 -j CHECKSUM --checksum-fill; /etc/init.d/iptables save",
        unless  => "iptables -t mangle -S POSTROUTING | grep -q \"^-A POSTROUTING -p udp -m udp --dport 68 -j CHECKSUM --checksum-fill\""
      }
    }
    /(?i)(debian|ubuntu)/ : {
      exec { "checksum_fill_bootpc":
        command => "iptables -t mangle -A POSTROUTING -p udp --dport 68 -j CHECKSUM --checksum-fill; iptables-save -c > /etc/iptables.rules",
        unless  => "iptables -t mangle -S POSTROUTING | grep -q \"^-A POSTROUTING -p udp -m udp --dport 68 -j CHECKSUM --checksum-fill\""
      }
    }
  }
}
