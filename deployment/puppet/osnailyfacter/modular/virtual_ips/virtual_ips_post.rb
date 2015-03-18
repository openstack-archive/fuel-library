require File.join File.dirname(__FILE__), '../test_common.rb'

class VirtualIPsPostTest < Test::Unit::TestCase

  def test_public_vip_ping
    ip = TestCommon::Settings.public_vip
    assert TestCommon::Network.ping?(ip), "Could not ping the public vip '#{ip}'!"
  end

  def test_management_vip_ping
    ip = TestCommon::Settings.management_vip
    assert TestCommon::Network.ping?(ip), "Could not ping the management vip '#{ip}'!"
  end

  def test_can_ping_the_default_router
    ip = TestCommon::Network.default_router
    assert TestCommon::Network.ping?(ip), "Cannot ping the default router '#{ip}'!"
  end

end
