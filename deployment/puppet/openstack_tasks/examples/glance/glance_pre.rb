require File.join File.dirname(__FILE__), '../test_common.rb'

BACKEND = 'glance-api'

class GlancePreTest < Test::Unit::TestCase

  def test_haproxy_glance_backend_present
    assert TestCommon::HAProxy.backend_present?(BACKEND), "There is no '#{BACKEND}' HAProxy backend!"
  end

  def test_amqp_accessible
    assert TestCommon::AMQP.connection?, 'Cannot connect to AMQP server!'
  end

end
