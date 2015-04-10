require File.join File.dirname(__FILE__), '../test_common.rb'

class PublicVipPingPreTest < Test::Unit::TestCase

  def test_pacemaker_is_online
    assert TestCommon::Pacemaker.online?, 'Could not query Pacemaker CIB!'
  end

  def test_hiera_data
    assert TestCommon::Settings.lookup('network_scheme'), 'No network_scheme in Hiera!'
  end

end
