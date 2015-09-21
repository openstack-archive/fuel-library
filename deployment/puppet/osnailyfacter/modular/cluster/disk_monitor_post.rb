require File.join File.dirname(__FILE__), '../test_common.rb'

class DiskMonitorPostTest < Test::Unit::TestCase
  def ubuntu?
    TestCommon::Facts.operatingsystem == 'Ubuntu'
  end

  def test_sysinfo_resource_started
    return unless ubuntu?
    assert TestCommon::Pacemaker.primitive_present?('sysinfo'), 'sysinfo is not created!'
  end
end

