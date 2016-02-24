require File.join File.dirname(__FILE__), '../test_common.rb'

class CeilometerComputePreTest < Test::Unit::TestCase

  def test_amqp_accessible
    host = TestCommon::Settings.amqp_hosts.split(':').first
    user = TestCommon::Settings.rabbit['user']
    password = TestCommon::Settings.rabbit['password']
    assert TestCommon::AMQP.connection?(user, password, host), 'Cannot connect to AMQP server!'
  end

end
