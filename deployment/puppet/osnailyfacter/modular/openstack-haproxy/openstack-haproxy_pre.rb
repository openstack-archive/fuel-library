require File.join File.dirname(__FILE__), '../test_common.rb'

class OpenstackHaproxyPreTest < Test::Unit::TestCase

  def test_haproxy_is_running
    assert TestCommon::Process.running?('haproxy'), 'Haproxy is not running!'
  end

end
