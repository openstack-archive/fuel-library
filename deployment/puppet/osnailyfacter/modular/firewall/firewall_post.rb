require File.join File.dirname(__FILE__), '../test_common.rb'

COMMON_RULES = [
    'accept all icmp requests',
    'accept all to lo interface',
    'ssh',
    'iscsi',
    'ntp-server',
    'notrack gre',
    'accept gre',
    'vxlan_udp_port',
    ]

CONTROLLER_RULES = [
    'remote rabbitmq',
    'remote puppet',
    'local rabbitmq admin',
    'reject non-local rabbitmq admin',
    'allow connections from haproxy namespace',
    'http',
    'mysql',
    'keystone',
    'swift',
    'glance',
    'nova',
    'nova internal - no ssl',
    'rabbitmq',
    'memcache tcp',
    'memcache udp',
    'rsync',
    'neutron',
    'dns-server udp',
    'dns-server tcp',
    'dhcp-server',
    'corosync-input',
    'corosync-output',
    'pcsd-server',
    'openvswitch db',
    'ceilometer',
    'murano-rabbitmq',
    'heat-api',
    'heat-api-cfn',
    'heat-api-cloudwatch',
]

COMPUTE_RULES = [
    'libvirt',
    'libvirt-migration',
]

def role
  TestCommon::Settings.role.to_s
end

class FirewallPostTest < Test::Unit::TestCase
  def self.create_tests(rules)
    rules.each do |rule|
      method_name = "test_iptables_have_rule_#{rule.gsub ' ', '_'}"
      define_method method_name do
        assert TestCommon::Network.iptables_rules.include?(rule), "Iptables don't have the '#{rule}' rule!'"
      end
    end
  end

  def self.run_tests
    create_tests COMMON_RULES
    if %w(controller primary-controller).include? role
      create_tests CONTROLLER_RULES
    elsif role == "compute"
      create_tests COMPUTE_RULES
    end
  end
end

FirewallPostTest.run_tests
