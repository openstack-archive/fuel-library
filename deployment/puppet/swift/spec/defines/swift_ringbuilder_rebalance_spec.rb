require 'spec_helper'
describe 'swift::ringbuilder::rebalance' do
  describe 'with allowed titles' do
    ['object', 'container', 'account'].each do |type|
      describe "when title is #{type}" do
        let :title do
          type
        end
        it { is_expected.to contain_exec("rebalance_#{type}").with(
          {:command     => "swift-ring-builder /etc/swift/#{type}.builder rebalance",
           :path        => ['/usr/bin'],
           :refreshonly => true}
        )}
      end
    end
  end
  describe 'with valid seed' do
    let :params do
      { :seed => '999' }
    end
    let :title do
      'object'
    end
    it { is_expected.to contain_exec("rebalance_object").with(
      {:command     => "swift-ring-builder /etc/swift/object.builder rebalance 999",
       :path        => ['/usr/bin'],
       :refreshonly => true}
    )}
  end
  describe 'with an invalid seed' do
    let :title do
      'object'
    end
    let :params do
      { :seed => 'invalid' }
    end
    it 'should raise an error' do
      expect { catalogue }.to raise_error(Puppet::Error)
    end
  end
  describe 'with an invalid title' do
    let :title do
      'invalid'
    end
    it 'should raise an error' do
      expect { catalogue }.to raise_error(Puppet::Error)
    end
  end

end
