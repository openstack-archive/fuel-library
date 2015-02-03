require 'hiera'
require 'test/unit'

def hiera
  return $hiera if $hiera
  $hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
end

def roles
  return $roles if $roles
  $roles = hiera.lookup 'roles', nil, {}
end


class CinderVmwarePreTest < Test::Unit::TestCase

  def test_roles
    assert roles, 'Could not get the roles data!'
    assert roles.is_a?(Array), 'Incorrect roles data!'
    assert roles.find_index("cinder-vmware"), 'Wrong role for this node!'
  end

end
