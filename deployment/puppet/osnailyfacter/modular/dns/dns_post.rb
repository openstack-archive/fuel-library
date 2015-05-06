require File.join File.dirname(__FILE__), '../test_common.rb'

class DnsPostTest < Test::Unit::TestCase

  def test_can_resolve_dns
    host = 'www.google.com'
    assert TestCommon::Network.resolve?(host), "
Cannot resolve host '#{host}'.
Please check the DNS servers on the settings page and network connectivity."
  end

end
