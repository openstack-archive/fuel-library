require File.join File.dirname(__FILE__), '../test_common.rb'

class PublicVipPingPostTest < Test::Unit::TestCase

  def ubuntu?
    TestCommon::Facts.operatingsystem == 'Ubuntu'
  end

  def test_contrack_resource_started
    return unless ubuntu?
    assert TestCommon::Pacemaker.primitive_present?('p_conntrackd'), 'p_conntrackd is not created!'
  end

end
