require File.join File.dirname(__FILE__), '../test_common.rb'

class AptProxyPostTest < Test::Unit::TestCase
  def test_apt_proxy_config_present
    config = '/etc/apt/apt.conf.d/90proxy'
    assert File.file?(config), 'APT proxy file was not created!'
  end
end
