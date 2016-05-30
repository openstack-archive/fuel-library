# ROLE: virt
# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: ironic
# ROLE: controller
# ROLE: compute
# ROLE: compute-vmware
# ROLE: cinder-vmware
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: ceph-osd
require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/hiera_default_route.pp'
describe manifest do
  shared_examples 'catalog' do

    network_metadata = Noop.hiera_hash 'network_metadata'
    network_scheme   = Noop.hiera_hash 'network_scheme'
    use_neutron      = Noop.hiera 'use_neutron'
    default_gateway  = Noop.hiera 'default_gateway'
    set_xps          = Noop.hiera 'set_xps', true
    set_rps          = Noop.hiera 'set_rps', true
    dpdk_config      = Noop.hiera_hash 'dpdk', {}
    enable_dpdk      = dpdk_config.fetch 'enabled', false
    mgmt_vrouter_vip = Noop.hiera 'management_vrouter_vip'
    roles            = Noop.hiera 'roles', []
    mongo_roles      = ['primary-mongo', 'mongo']

    in_group_with_vip = !network_scheme['endpoints']['br-mgmt']['IP'].find{
      |ipnet| IPAddr.new(ipnet).include?(IPAddr.new(mgmt_vrouter_vip))}.nil?

    if network_scheme['endpoints'].has_key?('br-ex')
      it { should contain_file('/etc/hiera/override/configuration/default_route.yaml').with(
        'ensure' => 'absent',
      )}
    elsif in_group_with_vip
      it { should contain_file('/etc/hiera/override/configuration/default_route.yaml').with_content(
        /gateway: "#{mgmt_vrouter_vip}"/
      )}
    else
      it { should contain_file('/etc/hiera/override/configuration/default_route.yaml').with(
        'ensure' => 'absent',
      )}
    end
  end

  test_ubuntu_and_centos manifest
end

