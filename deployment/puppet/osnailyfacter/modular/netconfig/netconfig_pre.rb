require File.join File.dirname(__FILE__), '../test_common.rb'

class NetconfigPreTest < Test::Unit::TestCase

  def test_nodes_present_in_hiera
    nodes = TestCommon::Settings.nodes
    assert nodes, 'Could not get the nodes data!'
    assert nodes.is_a?(Array), 'Incorrect nodes data!'
    assert nodes.any?, 'Empty nodes data!'
  end

end
