require File.join File.dirname(__FILE__), '../test_common.rb'

class IronicPreTest < Test::Unit::TestCase

  def test_amqp_accessible
    assert TestCommon::AMQP.connection?, 'Cannot connect to AMQP server!'
  end

  def test_haproxy_ironic_backend_present
    assert TestCommon::HAProxy.backend_present?('ironic-api'), 'No ironic-api haproxy backend!'
  end

  def test_haproxy_ironic_baremetal_backend_present
    assert TestCommon::HAProxy.backend_present?('ironic-baremetal'), 'No ironic-baremetal haproxy backend!'
  end

end
