require File.join File.dirname(__FILE__), '../test_common.rb'

class VcenterHooksPreTest < Test::Unit::TestCase

  def test_hiera_data
    assert TestCommon::Settings.lookup('vcenter'), 'No vcenter data in Hiera!'
  end

end
