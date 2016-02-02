require 'spec_helper'

describe 'l23network::l2::port', :type => :define do
  let(:title) { 'Spec for l23network::l2::port for SRIOV' }
  let(:facts) { {
      :osfamily => 'Debian',
      :operatingsystem => 'Ubuntu',
      :kernel => 'Linux',
      :l23_os => 'ubuntu',
      :l3_fqdn_hostname => 'stupid_hostname',
  } }
  let(:pre_condition) { [
      "class {'l23network': }"
  ] }


  context 'Create SRIOV port' do
    let(:params) do
      {
          :name => 'eth0',
          :provider => 'sriov',
          :vendor_specific => {
              'sriov_numvfs' => 7,
              'physnet'      => 'physnet2'
          }
      }
    end

    before(:each) do
      puppet_debug_override()
    end

    it do
      should compile.with_all_deps
    end

    it do
      should contain_l23_stored_config('eth0').with(
          {
              'ensure'  => 'present',
              'use_ovs' => nil,
              'if_type' => nil,
              'method'  => nil,
              'ipaddr'  => nil,
              'gateway' => nil,
              'vendor_specific' => {
                  'sriov_numvfs' => 7,
                  'physnet'      => 'physnet2'
              }
          }
      )
    end

    it do
      should contain_l2_port('eth0').with(
          {
              'ensure'  => 'present',
              'vendor_specific' => {
                  'sriov_numvfs' => 7,
                  'physnet'      => 'physnet2'
              }
          }
      ).that_requires('L23_stored_config[eth0]')
    end
  end
end
# vim: set ts=2 sw=2 et
