require File.join File.dirname(__FILE__), '../test_common.rb'
include TestCommon

PORT = 8777

PROCESSES = %w(
ceilometer-collector
ceilometer-agent-central
ceilometer-alarm-notifier
ceilometer-alarm-evaluator
ceilometer-api
)

PACEMAKER_SERVICES = %w(
p_openstack-ceilometer-central
p_openstack-ceilometer-alarm-evaluator
)

class CeilometerControllerPostTest < Test::Unit::TestCase

  def test_ceilometer_processes_running
    PROCESSES.each do |process|
      assert PS.running?(process), "'#{process}' is not running!"
    end
  end

  def test_ceilometer_api_public_url_accessible
    url = "http://#{Settings.public_vip}:#{PORT}"
    assert Net.url_accessible?(url), "Public Ceilometer API URL '#{url}' is not accessible!"
  end

  def test_ceilometer_api_management_url_accessible
    url = "http://#{Settings.management_vip}:#{PORT}"
    assert Net.url_accessible?(url), "Admin Ceilometer API URL '#{url}' is not accessible!"
  end

  def test_ceilometer_meter_list_run
    cmd = 'source /root/openrc && ceilometer meter-list'
    assert PS.run_successful?(cmd), "Could not run '#{cmd}'!"
  end

  def test_pacemaker_services_running
    PACEMAKER_SERVICES.each do |service|
      assert Pacemaker.primitive_started?(service), "Pacemaker service '#{service}' is not running!"
    end
  end

end
