require File.join File.dirname(__FILE__), '../test_common.rb'

class ApachePostTest < Test::Unit::TestCase

  def test_apache_80_on_public
    ip = TestCommon::Settings.public_address
    assert TestCommon::Network.connection?(ip, 80), 'Cannot connect to apache on the public address!'
  end

end
