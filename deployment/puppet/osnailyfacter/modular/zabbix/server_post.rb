require File.join File.dirname(__FILE__), '../test_common.rb'

class ZabbixServerPostTest < Test::Unit::TestCase

  def test_zabbix_is_running
    assert TestCommon::Process.running?('zabbix_server'), 'Zabbix server is not running!'
  end

  def test_zabbix_server_listen_port
    assert TestCommon::Network.connection?('127.0.0.1', 10051)
  end

  def test_can_auth_json_rpc
    url = 'http://localhost/zabbix/api_jsonrpc.php'
    zabbix = TestCommon::Settings.zabbix
    password = zabbix['password']
    username = zabbix['username']
    json =<<-eof
{
    "jsonrpc": "2.0",
    "method": "user.authenticate",
    "params": {
        "user": "#{username}",
        "password": "#{password}"
    },
    "auth": null,
    "id": 0
}
    eof
    response = TestCommon::Network.json_rpc url, json
    assert response.first == '200', 'Could not sent API request!'
    assert !response.last.include?('Login name or password is incorrect'), 'API Auth failed!'
  end

end
