require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/iptables.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    it 'should contain firewal rules' do

      should contain_firewallchain('INPUT:filter:IPv4')
      should contain_firewallchain('FORWARD:filter:IPv4')
      should contain_firewallchain('POSTROUTING:nat:IPv4')
      should contain_firewallchain('POSTROUTING:mangle:IPv4')
      should contain_firewallchain('ext-filter-input:filter:IPv4')
      should contain_firewallchain('ext-filter-forward:filter:IPv4')
      should contain_firewallchain('ext-nat-postrouting:nat:IPv4')
      should contain_firewallchain('ext-mangle-postrouting:mangle:IPv4')
      should contain_firewall('000 allow loopback')
      should contain_firewall('010 ssh')
      should contain_firewall('020 ntp')
      should contain_firewall('030 ntp_udp')
      should contain_firewall('040 snmp')
      should contain_firewall('050 nailgun_web')
      should contain_firewall('060 nailgun_internal')
      should contain_firewall('070 nailgun_internal_block_ext')
      should contain_firewall('080 postgres_local')
      should contain_firewall('090 postgres')
      should contain_firewall('100 postgres_block_ext')
      should contain_firewall('110 ostf_admin')
      should contain_firewall('120 ostf_local')
      should contain_firewall('130 ostf_block_ext')
      should contain_firewall('140 rsync')
      should contain_firewall('150 rsyslog')
      should contain_firewall('160 rsyslog')
      should contain_firewall('170 rabbitmq_admin_net')
      should contain_firewall('180 rabbitmq_local')
      should contain_firewall('190 rabbitmq_block_ext')
      should contain_firewall('200 fuelweb_port')
      should contain_firewall('210 keystone_admin')
      should contain_firewall('220 keystone_admin_port admin_net')
      should contain_firewall('230 nailgun_repo_admin')
      should contain_firewall('240 allow icmp echo-request')
      should contain_firewall('250 allow icmp echo-reply')
      should contain_firewall('260 allow icmp dest-unreach')
      should contain_firewall('270 allow icmp time-exceeded')
      should contain_firewall('970 externally defined rules: ext-filter-input')
      should contain_firewall('980 accept related established rules')
      should contain_firewall('999 iptables denied')
      should contain_firewall('010 forward admin_net')
      should contain_firewall('970 externally defined rules')
      should contain_firewall('980 forward admin_net conntrack')
      should contain_firewall('010 forward_admin_net')
      should contain_firewall('980 externally defined rules: ext-nat-postrouting')
      should contain_firewall('010 recalculate dhcp checksum')
      should contain_firewall('980 externally defined rules: ext-mangle-postrouting')

    end
  end
  run_test manifest
end
