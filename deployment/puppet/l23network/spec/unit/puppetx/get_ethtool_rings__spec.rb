require 'spec_helper'
require 'puppetx/l23_utils'

describe 'L23network' do
  context "get_ethtool_rings" do

    let(:output) do
%q(Ring parameters for eth0:
Pre-set maximums:
RX:		4096
RX Mini:	0
RX Jumbo:	0
TX:		4096
Current hardware settings:
RX:		256
RX Mini:	0
RX Jumbo:	0
TX:		256)
    end

    let(:maximums) do
      {
        'RX' => '4096',
        'TX' => '4096',
      }
    end

    let(:current) do
      {
        'RX' => '256',
        'TX' => '256',
      }
    end

    before do
      L23network.stubs(:`).with('ethtool -g eth0').returns(output)
    end

    it "should get pre-set maximums" do
      expect(L23network.get_ethtool_rings('eth0')).to eq(maximums)
    end

    it "should get current hardware settings" do
      expect(L23network.get_ethtool_rings('eth0', true)).to eq(current)
    end

  end
end
# vim: set ts=2 sw=2 et
