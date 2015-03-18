require File.join File.dirname(__FILE__), '../test_common.rb'

class HostsPreTest < Test::Unit::TestCase

  def test_hiera_has_nodes_data
    nodes_array = TestCommon::Settings.nodes
    assert nodes_array.is_a?(Array), 'Nodes data not found!'
    assert nodes_array.any?
  end

  def test_nodes_are_correct
    nodes_array = TestCommon::Settings.nodes

    nodes_array.each do |node|
      error = "Node #{node.inspect} is not correct!"
      assert node['internal_address'], error
      assert node['fqdn'], error
      assert node['name'], error
    end
  end

end
