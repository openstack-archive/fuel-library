require 'spec_helper'

describe 'l23network::interface_hotplug::network_interface', :type => :define do
  context 'just network-interface' do
    let(:title) { 'network-interface' }
    let(:facts) { {
      :operatingsystem => 'Ubuntu',
    } }

    let(:params) { {
      :interface => 'eth5',
    } }

    it do
      should contain_service('network-interface INTERFACE=eth5').with({
        'ensure' => 'stopped',
      })
    end

    it { should contain_service('network-interface INTERFACE=eth5').that_comes_before('Exec[up eth5]') }

    it do
      should contain_exec('up eth5').with({
        'command' => 'ifup --allow auto eth5',
      })
    end
  end
end
