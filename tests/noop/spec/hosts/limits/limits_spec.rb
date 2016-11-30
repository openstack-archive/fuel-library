# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: ironic
# ROLE: controller
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: ceph-osd
require 'spec_helper'
require 'shared-examples'
manifest = 'limits/limits.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:roles) do
      Noop.hiera 'roles'
    end

    let(:limits) do
      Noop.hiera 'limits', {}
    end

    let(:general_mof_limit) do
      Noop.puppet_function 'pick', limits['general_mof_limit'], '102400'
    end

    let(:libvirt_mof_limit) do
      Noop.puppet_function 'pick', limits['libvirt_mof_limit'], '102400'
    end

    it 'should configure general max open files limit' do
      should contain_limits__limits('*/nofile').with(
        'hard' => general_mof_limit,
        'soft' => general_mof_limit
      )
      should contain_limits__limits('root/nofile').with(
        'hard' => general_mof_limit,
        'soft' => general_mof_limit
      )
    end

    if Noop.puppet_function 'member', roles, 'compute'
      it 'should configure libvirt max open files limit' do
        should contain_file('/etc/init/libvirtd.override').with( 'content' => "limit nofile #{libvirt_mof_limits} #{libvirt_mof_limit}" )
      end
    end

  end
end
