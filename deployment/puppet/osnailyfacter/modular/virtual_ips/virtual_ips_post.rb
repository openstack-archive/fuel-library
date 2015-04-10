require File.join File.dirname(__FILE__), '../test_common.rb'

class VirtualIPsPostTest < Test::Unit::TestCase

  def has_public?
    TestCommon::Settings.lookup 'public_vip'
  end

  def test_can_ping_the_default_router
    ip = TestCommon::Network.default_router
    assert TestCommon::Network.ping?(ip), "Cannot ping the default router '#{ip}'!"
  end

  def test_public_vip_ping
    return unless has_public?
    ip = TestCommon::Settings.public_vip
    assert TestCommon::Network.ping?(ip), "Could not ping the public vip '#{ip}'!"
  end

  def test_public_vrouter_vip_ping
    return unless has_public?
    ip = TestCommon::Settings.public_vrouter_vip
    assert TestCommon::Network.ping?(ip), "Could not ping the public vrouter vip '#{ip}'!"
  end

  def test_management_vip_ping
    ip = TestCommon::Settings.management_vip
    assert TestCommon::Network.ping?(ip), "Could not ping the management vip '#{ip}'!"
  end

  def test_management_vrouter_vip_ping
    ip = TestCommon::Settings.management_vrouter_vip
    assert TestCommon::Network.ping?(ip), "Could not ping the management vrouter vip '#{ip}'!"
  end

  def test_vip_ocf_present
    file = '/usr/lib/ocf/resource.d/fuel/ns_IPaddr2'
    assert File.exist?(file), 'VIP OCF file is missing!'
  end

  def test_paceamaker_management_vips
    assert TestCommon::Pacemaker.primitive_started?('vip__management'), 'vip__management Pacemaker service is not started!'
    assert TestCommon::Pacemaker.primitive_started?('vip__management_vrouter'), 'vip__management_vrouter Pacemaker service is not started!'
  end

  def test_paceamaker_public_vips
    return unless has_public?
    assert TestCommon::Pacemaker.primitive_started?('vip__public'), 'vip__public Pacemaker service is not started!'
    assert TestCommon::Pacemaker.primitive_started?('vip__public_vrouter'), 'vip__public_vrouter Pacemaker service is not started!'
  end

end
