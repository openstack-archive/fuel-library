require File.join File.dirname(__FILE__), '../test_common.rb'

PROCESSES = %w(
crmd
lrmd
pengine
attrd
stonithd
cib
pacemakerd
corosync
)

class ClusterPostTest < Test::Unit::TestCase
  def self.create_tests
    PROCESSES.each do |process|
      method_name = "test_process_#{process}_running"
      define_method method_name do
        assert TestCommon::Process.running?(process), "Process '#{process}' is not running!"
      end
    end
  end

  def test_pacemaker_is_online
    assert TestCommon::Pacemaker.online?, 'Could not query Pacemaker CIB!'
  end
end

ClusterPostTest.create_tests
