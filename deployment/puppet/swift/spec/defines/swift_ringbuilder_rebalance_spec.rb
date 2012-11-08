require 'spec_helper'
describe 'swift::ringbuilder::rebalance' do
  describe 'with allowed titles' do
    ['object', 'container', 'account'].each do |type|
      describe "when title is #{type}" do
        let :title do
          type
        end
        it { should contain_exec("rebalance_#{type}").with(
          {:command     => "swift-ring-builder /etc/swift/#{type}.builder rebalance",
           :path        => '/usr/bin',
           :refreshonly => true}
        )}
      end
    end
  end
  describe 'with an invalid title' do
    let :title do
      'invalid'
    end
    it 'should raise an error' do
      expect { subject }.to raise_error(Puppet::Error)
    end
  end

end
