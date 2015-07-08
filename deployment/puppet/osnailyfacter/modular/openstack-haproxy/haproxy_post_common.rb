require File.join File.dirname(__FILE__), '../test_common.rb'

class OpenstackHaproxyPostTest < Test::Unit::TestCase
  def self.create_tests
    expected_backends.each do |backend|
      method_name = "test_backend_#{backend}_present"
      define_method method_name do
        assert TestCommon::HAProxy.backend_present?(backend), "There is no '#{backend}' HAProxy backend!"
      end
    end
  end
end

