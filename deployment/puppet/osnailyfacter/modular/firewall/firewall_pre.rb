require File.join File.dirname(__FILE__), '../test_common.rb'

class FirewallPreTest < Test::Unit::TestCase
  def test_iptables_installed
    assert TestCommon::Process.command_present?('iptables'), 'Iptables is not installed!'
  end
end
