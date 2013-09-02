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


# add nat tables for nodes range
class cobbler::nat(
  $nat_range,
) {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  exec { 'enable_forwarding':
    command => 'echo 1 > /proc/sys/net/ipv4/ip_forward',
    unless  => 'cat /proc/sys/net/ipv4/ip_forward | grep -q 1',
  }
  exec { 'save_ipv4_forward':
    command => 'sed -i --follow-symlinks -e "/net\.ipv4\.ip_forward/d" \
                   /etc/sysctl.conf && echo "net.ipv4.ip_forward = 1" >> \
                   /etc/sysctl.conf',
    unless  => 'grep -q "^\s*net\.ipv4\.ip_forward = 1" /etc/sysctl.conf',
  }

  case $::operatingsystem {
    /(?i)(centos|redhat)/: {
      exec { 'enable_nat_all':
        command => "iptables -t nat -I POSTROUTING 1 \
                    -s ${nat_range} ! -d ${nat_range} -j MASQUERADE; \
                    /etc/init.d/iptables save",
        unless  => "iptables -t nat -S POSTROUTING | grep -q \"^-A POSTROUTING \
                   -s ${nat_range} ! -d ${nat_range} -j MASQUERADE\""
      }

      exec { 'enable_nat_filter':
        command => 'iptables -t filter -I FORWARD 1 -j ACCEPT; \
                   /etc/init.d/iptables save',
        unless  => 'iptables -t filter -S FORWARD | grep -q "^-A FORWARD \
                   -j ACCEPT"'
      }

    }
    /(?i)(debian|ubuntu)/: {
      # In order to save these rules and to make them raising on
      #  boot you supposed to
      # define to resources File["/etc/network/if-post-down.d/iptablessave"]
      # and File["/etc/network/if-pre-up.d/iptablesload"].
      #  Those two resources already
      # defined in cobbler::iptables class, so if you use default init.pp file
      # you already have those files defined

      exec { 'enable_nat_all':
        command => "iptables -t nat -I POSTROUTING 1 \
                    -s ${nat_range} ! -d ${nat_range} -j MASQUERADE; \
                    iptables-save -c > /etc/iptables.rules",
        unless  => "iptables -t nat -S POSTROUTING | grep -q \"^-A POSTROUTING \
                   -s ${nat_range} ! -d ${nat_range} -j MASQUERADE\""
      }

      exec { 'enable_nat_filter':
        command => 'iptables -t filter -I FORWARD 1 -j ACCEPT; \
                   iptables-save -c > /etc/iptables.rules',
        unless  => 'iptables -t filter -S FORWARD | grep -q "^-A \
                   FORWARD -j ACCEPT"'
      }
    }
    default: {}
  }
}
