require File.join File.dirname(__FILE__), '../test_common.rb'

class ZabbixServerPostTest < Test::Unit::TestCase

  def test_zabbix_is_running
    assert TestCommon::Process.running?('zabbix_server'), 'Zabbix server is not running!'
  end

end
