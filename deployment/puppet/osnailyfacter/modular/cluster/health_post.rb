require File.join File.dirname(__FILE__), '../test_common.rb'

class HealthPostTest < Test::Unit::TestCase
  def ubuntu?
    TestCommon::Facts.operatingsystem == 'Ubuntu'
  end

  def test_sysinfo_resource_started
    return unless ubuntu?
    fqdn = TestCommon::Settings.fqdn
    assert TestCommon::Pacemaker.primitive_present?("sysinfo_#{fqdn}"), 'sysinfo is not created!'
  end
end

