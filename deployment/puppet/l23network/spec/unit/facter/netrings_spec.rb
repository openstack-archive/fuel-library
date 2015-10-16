require 'spec_helper'
require 'facter/util/ip'

describe 'netrings', :type => :fact do

  before { Facter.clear }

  let(:e1000g0_output) do
%q(Ring parameters for e1000g0:
Pre-set maximums:
RX:            4096
RX Mini:       0
RX Jumbo:      0
TX:            4096
Current hardware settings:
RX:            256
RX Mini:       0
RX Jumbo:      0
TX:            256)
  end

  let(:nge0_output) do
%q(Ring parameters for nge0:
)
  end

  context 'with two interfaces' do
    before :each do
      Facter::Util::Resolution.stubs(:exec).with('uname -s').returns('Linux')
      Facter::Util::IP.stubs(:get_interfaces).returns(%w(e1000g0 nge0))
      Facter::Util::Resolution.stubs(:exec).with("ethtool -g e1000g0 2>/dev/null").returns(e1000g0_output)
      Facter::Util::Resolution.stubs(:exec).with("ethtool -g nge0 2>/dev/null").returns(nge0_output)
    end

      it 'should return info only for one' do
        expect(Facter.fact(:netrings).value).to eq({
      'e1000g0' => {
        'maximums' => {
          'RX' => '4096',
          'TX' => '4096'
        },
        'current' => {
          'RX' => '256',
          'TX' => '256'
        }
      }
    })
      end
  end

end
