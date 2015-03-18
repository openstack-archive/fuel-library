require File.join File.dirname(__FILE__), '../test_common.rb'

RULES = [
    'accept all to lo interface',
    'accept related established rules',
    'ssh',
    'http',
    'mysql',
    'keystone',
    'swift',
    'glance',
    'nova',
    'rabbitmq',
    'memcached tcp',
    'memcached udp',
    'rsync',
    'iscsi',
    'neutron',
    'dns-server',
    'dhcp-server',
    'ntp-server',
    'corosync-input',
    'corosync-output',
    'openvswitch db',
    'nrpe-server',
    'libvirt',
    'libvirt migration',
    'vnc ports',
    'ceilometer',
    'notrack gre',
    'accept gre',
    'drop all other requests',
    'remote puppet',
    'remote rabbitmq',
]

class FirewallPostTest < Test::Unit::TestCase
  def self.create_tests
    RULES.each do |rule|
      method_name = "test_iptables_have_rule_#{rule.gsub ' ', '_'}"
      define_method method_name do
        assert TestCommon::Network.iptables_rules.include?(rule), "Iptables don't have the '#{rule}' rule!'"
      end
    end
  end
end

FirewallPostTest.create_tests
