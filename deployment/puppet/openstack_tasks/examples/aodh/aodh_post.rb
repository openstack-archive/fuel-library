require File.join File.dirname(__FILE__), '../test_common.rb'

PORT = 8042

PROCESSES = %w(
aodh-notifier
aodh-evaluator
aodh-listener
aodh-api
)

if TestCommon::Facts.osfamily == 'Debian'
PACEMAKER_SERVICES = %w(
p_aodh-evaluator
)
end

class AodhControllerPostTest < Test::Unit::TestCase

  def test_aodh_processes_running
    PROCESSES.each do |process|
      assert TestCommon::Process.running?(process), "'#{process}' is not running!"
    end
  end

  def test_haproxy_aodh_backend_online
    assert TestCommon::HAProxy.backend_up?('aodh'), "HAProxy backend 'aodh' is not online!"
  end

  def test_pacemaker_services_running
    return unless PACEMAKER_SERVICES
    PACEMAKER_SERVICES.each do |service|
      assert TestCommon::Pacemaker.primitive_started?(service), "Pacemaker service '#{service}' is not running!"
    end
  end

end
