require File.join File.dirname(__FILE__), '../test_common.rb'
include TestCommon

class CeilometerComputePreTest < Test::Unit::TestCase

  def test_amqp_accessible
    user = Settings.rabbit['user']
    password = Settings.rabbit['password']
    host = Settings.management_vip
    assert AMQP.connection?(user, password, host), 'Cannot connect to AMQP server!'
  end

end
