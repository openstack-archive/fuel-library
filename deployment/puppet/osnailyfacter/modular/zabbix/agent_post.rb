require File.join File.dirname(__FILE__), '../test_common.rb'

class ZabbixAgentPostTest < Test::Unit::TestCase

  def test_zabbix_agent_is_running
    assert TestCommon::Process.running?('/usr/sbin/zabbix_agentd'), 'Zabbix server is not running!'
  end

  def test_zabbix_agent_listen_port
    assert TestCommon::Network.connection?('127.0.0.1', 10050)
  end

end
