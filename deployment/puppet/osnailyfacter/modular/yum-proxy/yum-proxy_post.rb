require File.join File.dirname(__FILE__), '../test_common.rb'

class YumProxyPostTest < Test::Unit::TestCase
  def test_yum_proxy_config_present
    config = '/etc/yum.conf'
    assert TestCommon::Config.has_line?(config, /^proxy=/), 'No proxy in yum.conf'
  end
end
