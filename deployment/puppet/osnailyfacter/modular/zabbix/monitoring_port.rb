require File.join File.dirname(__FILE__), '../test_common.rb'

class ZabbixMonitoringPostTest < Test::Unit::TestCase

  def test_zabbix_agent_is_running
    assert TestCommon::Process.running?('zabbix-agent'), 'Zabbix server is not running!'
  end

end
