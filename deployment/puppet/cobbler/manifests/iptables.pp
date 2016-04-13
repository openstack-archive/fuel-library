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


class cobbler::iptables (

  $chain = 'INPUT',

) {

  case $::operatingsystem {
    /(?i)(debian|ubuntu)/:{
      file { '/etc/network/if-post-down.d/iptablessave':
        content => template('cobbler/ubuntu/iptablessave.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
      }
      file { '/etc/network/if-pre-up.d/iptablesload':
        content => template('cobbler/ubuntu/iptablesload.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
      }
    }
  }

  firewall { '101 dns_tcp':
    chain  => $chain,
    dport  => '53',
    proto  => 'tcp',
    action => 'accept',
  }
  firewall { '102 dns_udp':
    chain  => $chain,
    dport  => '53',
    proto  => 'udp',
    action => 'accept',
  }
  firewall { '103 dhcp':
    chain  => $chain,
    dport  => ['67','68'],
    proto  => 'udp',
    action => 'accept',
  }
  firewall { '104 tftp':
    chain  => $chain,
    dport  => '69',
    proto  => 'udp',
    action => 'accept',
  }
  firewall { '105 squidproxy':
    chain  => $chain,
    dport  => '3128',
    proto  => 'tcp',
    action => 'accept',
  }
  firewall { '106 cobbler_web':
    chain  => $chain,
    dport  => ['80','443'],
    proto  => 'tcp',
    action => 'accept',
  }
}
