require 'spec_helper'

describe 'l23network::interface_hotplug', :type => :class do

  context 'l23network::interface_hotplug module on Ubuntu' do
    let(:facts) { {
      :operatingsystem => 'Ubuntu',
      :upstart_network_interface_instances => 'eth11,eth12,eth13'
    } }

    it do
      should compile.with_all_deps
    end

    it { should contain_l23network__interface_hotplug__network_interface('eth11').that_comes_before('File[disable-hotplug]') }
    it { should contain_l23network__interface_hotplug__network_interface('eth12').that_comes_before('File[disable-hotplug]') }
    it { should contain_l23network__interface_hotplug__network_interface('eth13').that_comes_before('File[disable-hotplug]') }

    it { should contain_file('disable-hotplug').that_comes_before('L23_stored_config[lo]') }

    it do should contain_l23_stored_config('lo').with({
           'ensure' => 'present',
           'ipaddr' => '127.0.0.1/8',
           'method' => 'static',
           'onboot' => true,
        })
    end

  end

  context 'l23network::interface_hotplug module on CentOS' do
    let(:facts) { {
      :operatingsystem => 'Centos',
      :upstart_network_interface_instances => 'eth21'
    } }

    it do
      should compile.with_all_deps
    end

    it { should_not contain_l23network__interface_hotplug__network_interface('eth21') }

    it { should_not contain_file('disable-hotplug') }

    it do should_not contain_l23_stored_config('lo').with({
           'ensure' => 'present',
           'ipaddr' => '127.0.0.1/8',
           'method' => 'static',
           'onboot' => true,
        })
    end
  end

end
