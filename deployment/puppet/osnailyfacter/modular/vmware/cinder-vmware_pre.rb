require File.join File.dirname(__FILE__), '../test_common.rb'

class CinderVmwarePreTest < Test::Unit::TestCase

  def test_roles_present
    roles = TestCommon::Settings.roles
    assert roles, 'Could not get the roles data!'
    assert roles.is_a?(Array), 'Incorrect roles data!'
    assert roles.find_index('cinder-vmware'), 'Wrong role for this node!'
  end

end
