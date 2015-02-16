require 'hiera'
require 'test/unit'

class HostsPreTest < Test::Unit::TestCase

  def test_hiera_has_nodes_data
    hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
    nodes_array = hiera.lookup 'nodes', nil, {}
    assert nodes_array.is_a?(Array), 'Nodes data not found!'
    assert nodes_array.any?
  end

  def test_nodes_are_correct
    hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
    nodes_array = hiera.lookup 'nodes', nil, {}

    nodes_array.each do |node|
      error = "Node #{node.inspect} is not correct!"
      assert node['internal_address'], error
      assert node['fqdn'], error
      assert node['name'], error
    end
  end

end
