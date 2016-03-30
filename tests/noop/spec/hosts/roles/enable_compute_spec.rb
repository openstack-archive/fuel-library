# HIERA: neut_gre.generate_vms
# HIERA: neut_vlan.ceph.ceil-compute.overridden_ssl
# HIERA: neut_vlan.ceph.compute-ephemeral-ceph
# HIERA: neut_vlan.cinder-block-device.compute
# HIERA: neut_vlan.compute.nossl
# HIERA: neut_vlan.compute.ssl
# HIERA: neut_vlan.compute.ssl.overridden
# HIERA: neut_vlan_l3ha.ceph.ceil-compute
# HIERA: neut_vxlan_dvr.murano.sahara-compute

require 'spec_helper'
require 'shared-examples'
manifest = 'roles/enable_compute.pp'

describe manifest do
  shared_examples 'catalog' do

    it 'should contain nova-compute service' do
      service_name = case facts[:operatingsystem]
      when 'Ubuntu'
        'nova-compute'
      when 'CentOS'
        'openstack-nova-compute'
      else
        'nova-compute'
      end

      is_expected.to contain_service('nova-compute').with(
        :ensure     => 'running',
        :name       => service_name,
        :enable     => true,
        :hasstatus  => true,
        :hasrestart => true,
      )
    end

    if Noop.hiera('use_ovs') && Noop.hiera('role') == 'compute'
      neutron_integration_bridge = 'br-int'
      bridge_exists_check = "ovs-vsctl br-exists #{neutron_integration_bridge}"

      it 'should contain wait-for-int-br exec' do
        is_expected.to contain_exec('wait-for-int-br').with(
            :command   => bridge_exists_check,
            :unless    => bridge_exists_check,
            :try_sleep => 6,
            :tries     => 10,
          ).that_comes_before('Service[nova-compute]')
      end
    end

  end

  test_ubuntu_and_centos manifest
end
