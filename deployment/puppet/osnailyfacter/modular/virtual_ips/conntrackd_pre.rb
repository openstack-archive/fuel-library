require File.join File.dirname(__FILE__), '../test_common.rb'

class ContrackdPreTest < Test::Unit::TestCase

  def test_pacemaker_is_online
    assert TestCommon::Pacemaker.online?, 'Could not query Pacemaker CIB!'
  end

end
