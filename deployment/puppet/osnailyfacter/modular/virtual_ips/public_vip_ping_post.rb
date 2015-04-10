require File.join File.dirname(__FILE__), '../test_common.rb'

class PublicVipPingPostTest < Test::Unit::TestCase

  def has_public?
    TestCommon::Settings.lookup 'public_vip'
  end

  def test_ping_resource_started
    return unless has_public?
    assert TestCommon::Pacemaker.primitive_started?('ping_vip__public'), 'ping_vip__public is not started!'
  end

  def test_paceamaker_public_vips
    return unless has_public?
    assert TestCommon::Pacemaker.primitive_started?('vip__public'), 'vip__public Pacemaker service is not started!'
    assert TestCommon::Pacemaker.primitive_started?('vip__public_vrouter'), 'vip__public_vrouter Pacemaker service is not started!'
  end

end
