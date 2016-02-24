require File.join File.dirname(__FILE__), '../test_common.rb'

PROCESSES = %w(
swift-proxy-server
swift-account-server
swift-container-server
swift-object-server
)

class SwiftPostTest < Test::Unit::TestCase
  def self.create_tests
    PROCESSES.each do |process|
      method_name = "test_process_#{process}_running"
      define_method method_name do
        assert TestCommon::Process.running?(process), "Process '#{process}' is not running!"
      end
    end
  end

  def test_swift_backend_online
    assert TestCommon::HAProxy.backend_up?('swift'), 'Haproxy swift backend is down!'
  end
end

SwiftPostTest.create_tests
