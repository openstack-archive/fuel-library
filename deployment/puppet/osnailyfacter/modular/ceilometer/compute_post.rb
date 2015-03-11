require File.join File.dirname(__FILE__), '../test_common.rb'
include TestCommon

PORT = 8777

PROCESSES = %w(
ceilometer-agent-compute
)

class CeilometerComputePostTest < Test::Unit::TestCase

  def test_ceilometer_processes_running
    PROCESSES.each do |process|
      assert PS.running?(process), "'#{process}' is not running!"
    end
  end

end
