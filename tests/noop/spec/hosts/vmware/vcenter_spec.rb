require 'spec_helper'
require 'shared-examples'
manifest = 'vmware/vcenter.pp'

describe manifest do
  shared_examples 'catalog' do
    use_vcenter = Noop.hiera('use_vcenter', false)
    network_manager = Noop.hiera_structure('novanetwork_parameters/network_manager')
    public_ssl = Noop.hiera_structure('public_ssl/services')
    if use_vcenter
      if network_manager == 'VlanManager'
        it 'should declare vmware::controller with vlan_interface option set to vmnic0' do
          should contain_class('vmware::controller').with(
            'vlan_interface' => 'vmnic0',
          )
        end
      end
      if public_ssl
        it 'should properly configure vncproxy WITH ssl' do
          vncproxy_host = Noop.hiera_structure('public_ssl/hostname')
          should contain_class('vmware::controller').with(
            'vncproxy_host'     => vncproxy_host,
            'vncproxy_protocol' => 'https',
          )
        end
      else
        it 'should properly configure vncproxy WITHOUT ssl' do
          vncproxy_host = Noop.hiera('public_vip')
          should contain_class('vmware::controller').with(
            'vncproxy_host'     => vncproxy_host,
            'vncproxy_protocol' => 'http',
          )
        end
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
 end
