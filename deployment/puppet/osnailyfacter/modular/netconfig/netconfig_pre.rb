require 'hiera'
require 'test/unit'

def hiera
  return $hiera if $hiera
  $hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
end

def nodes
  return $nodes if $nodes
  $nodes = hiera.lookup 'nodes', nil, {}
end

class NetconfigPreTest < Test::Unit::TestCase

  def test_nodes_present_in_hiera
    assert nodes, 'Could not get the nodes data!'
    assert nodes.is_a?(Array), 'Incorrect nodes data!'
    assert nodes.any?, 'Empty nodes data!'
  end

end
