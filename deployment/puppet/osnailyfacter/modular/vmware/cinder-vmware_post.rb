require File.join File.dirname(__FILE__), '../test_common.rb'

class CinderVmwarePostTest < Test::Unit::TestCase

  def test_process
    assert TestCommon::Process.running?('/etc/cinder/cinder.d/vmware'), 'Process cinder-volume --config /etc/cinder/cinder.d/vmware-N.conf is not running!'
  end

end
