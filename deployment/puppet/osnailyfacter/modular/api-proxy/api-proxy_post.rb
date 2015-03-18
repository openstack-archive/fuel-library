require File.join File.dirname(__FILE__), '../test_common.rb'

class ApiProxyPostTest < Test::Unit::TestCase
  def test_api_proxy_online
    assert TestCommon::Network.connection?('localhost', 8888), 'Cannot connect to API proxy!'
  end
end

