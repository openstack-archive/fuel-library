require 'test/unit'
require 'socket'

def test_connection(host, port)
  begin
    s = TCPSocket.open(host, port)
    s.close
  rescue
    return false
  end
  true
end

def api_proxy_online?
  test_connection('localhost', '8888')
end

class ApiProxyPostTest < Test::Unit::TestCase
  def test_api_porxy_online
    assert api_proxy_online?, 'Can not connect to API proxy!'
  end
end

