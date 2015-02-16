require 'hiera'
require 'test/unit'

def iptables
  return $iptables if $iptables
  output = `iptables-save`
  code = $?.exitstatus
  return unless code == 0
  comments = []
  output.split("\n").each do |line|
    line =~ /--comment\s+"(.*?)"/
    next unless $1
    comment = $1.chomp.strip.gsub /^\d+\s+/, ''
    comments << comment
  end
  $iptables = comments
end

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
        assert iptables.include?(rule), "Iptables don't have the '#{rule}' rule!'"
      end
    end
  end
end

FirewallPostTest.create_tests
