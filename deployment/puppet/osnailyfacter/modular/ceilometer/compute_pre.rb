require File.join File.dirname(__FILE__), '../test_common.rb'

class CeilometerComputePreTest < Test::Unit::TestCase

  def test_amqp_accessible
    assert TestCommon::AMQP.connection?, 'Cannot connect to AMQP server!'
  end

end
