require File.join File.dirname(__FILE__), '../test_common.rb'

PORT = 8777

PROCESSES = %w(
ceilometer-collector
ceilometer-polling
ceilometer-agent-notification
ceilometer-alarm-notifier
ceilometer-alarm-evaluator
ceilometer-api
)

if TestCommon::Facts.osfamily == 'RedHat'
PACEMAKER_SERVICES = %w(
p_openstack-ceilometer-central
p_openstack-ceilometer-alarm-evaluator
)
elsif TestCommon::Facts.osfamily == 'Debian'
PACEMAKER_SERVICES = %w(
p_ceilometer-agent-central
p_ceilometer-alarm-evaluator
)
end

class CeilometerControllerPostTest < Test::Unit::TestCase

  def test_ceilometer_processes_running
    PROCESSES.each do |process|
      assert TestCommon::Process.running?(process), "'#{process}' is not running!"
    end
  end

  def test_haproxy_ceilometer_backend_online
    assert TestCommon::HAProxy.backend_up?('ceilometer'), "HAProxy backend 'ceilometer' is not online!"
  end

  def test_ceilometer_meter_list_run
    cmd = '. /root/openrc && ceilometer meter-list'
    assert TestCommon::Process.run_successful?(cmd), "Could not run '#{cmd}'!"
  end

  def test_pacemaker_services_running
    return unless PACEMAKER_SERVICES
    PACEMAKER_SERVICES.each do |service|
      assert TestCommon::Pacemaker.primitive_started?(service), "Pacemaker service '#{service}' is not running!"
    end
  end

end
