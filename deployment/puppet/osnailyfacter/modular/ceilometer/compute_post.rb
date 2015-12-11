require File.join File.dirname(__FILE__), '../test_common.rb'

PORT = 8777

PROCESSES = %w(
ceilometer-polling
)

class CeilometerComputePostTest < Test::Unit::TestCase

  def test_ceilometer_processes_running
    PROCESSES.each do |process|
      assert TestCommon::Process.running?(process), "'#{process}' is not running!"
    end
  end

end
