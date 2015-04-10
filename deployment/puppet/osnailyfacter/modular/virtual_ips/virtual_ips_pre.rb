require File.join File.dirname(__FILE__), '../test_common.rb'

class VirtualIpsPrePreTest < Test::Unit::TestCase

  def test_pacemaker_is_online
    assert TestCommon::Pacemaker.online?, 'Could not query Pacemaker CIB!'
  end

  def test_hiera_data
    assert TestCommon::Settings.lookup('management_vip'), 'No management_vip in Hiera!'
    assert TestCommon::Settings.lookup('management_vrouter_vip'), 'No management_vrouter_vip in Hiera!'
    if TestCommon::Settings.lookup 'public_int'
      assert TestCommon::Settings.lookup('public_vip'), 'No public_vip in Hiera!'
      assert TestCommon::Settings.lookup('public_vrouter_vip'), 'No public_vrouter_vip in Hiera!'
    end
  end

end
