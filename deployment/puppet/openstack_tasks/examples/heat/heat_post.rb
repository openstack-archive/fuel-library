require File.join File.dirname(__FILE__), '../test_common.rb'

PROCESSES = %w(
heat-api
heat-api-cfn
heat-api-cloudwatch
heat-engine
)

BACKENDS = %w(
heat-api
heat-api-cfn
heat-api-cloudwatch
)

HOSTS = {
  'http' => TestCommon::Settings.public_vip,
  'http' => TestCommon::Settings.management_vip,
}

PORTS = {
  'api' => 8004,
  'api-cfn' => 8003,
  'api-cloudwatch' => 8000,
}

class HeatPostTest < Test::Unit::TestCase
  def self.create_tests
    PROCESSES.each do |process|
      method_name = "test_process_#{process}_running"
      define_method method_name do
        assert TestCommon::Process.running?(process), "Process '#{process}' is not running!"
      end
    end

    BACKENDS.each do |backend|
      method_name = "test_backend_#{backend}_online"
      define_method method_name do
        assert TestCommon::HAProxy.backend_up?(backend), "HAProxy backend '#{backend}' is not online!"
      end
    end

    HOSTS.each do |host_type, ip|
      PORTS.each do |port_type, port|
        method_name = "test_#{host_type}_heat_#{port_type}_accessible"
        define_method method_name do
          url = "#{host_type}://#{ip}:#{port}"
          assert TestCommon::Network.url_accessible?(url), "URL '#{url}' is unaccessible?"
        end
      end
    end

    def test_heat_stack_list_run
      assert TestCommon::Process.run_successful?('. /root/openrc && heat stack-list'), 'Could not run heat-stack list!'
    end

    def test_heat_trusts_present
      assert TestCommon::Config.value?('/etc/heat/heat.conf', 'deferred_auth_method', 'trusts'), 'deferred_auth_method is not found in heat.conf'
      assert TestCommon::Config.value?('/etc/heat/heat.conf', 'trusts_delegated_roles', nil), 'trusts_delegated_roles is found in heat.conf'
    end

    def test_heat_domain_present
      password = TestCommon::Settings.heat['user_password']
      assert TestCommon::Config.value?('/etc/heat/heat.conf', 'stack_domain_admin', 'heat_admin'), 'stack_domain_admin is not found in heat.conf'
      assert TestCommon::Config.value?('/etc/heat/heat.conf', 'stack_domain_admin_password', password), 'stack_domain_admin_password is not found in heat.conf'
    end

  end
end

HeatPostTest.create_tests
