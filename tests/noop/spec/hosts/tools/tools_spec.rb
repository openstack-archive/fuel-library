# RUN: neut_gre.generate_vms ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.cinder-block-device.compute ubuntu
# RUN: neut_vlan.compute.nossl ubuntu
# RUN: neut_vlan.compute.ssl ubuntu
# RUN: neut_vlan.compute.ssl.overridden ubuntu
# RUN: neut_vlan.ironic.conductor ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-ceph-osd ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-mongo ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-cinder ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'tools/tools.pp'

tools = [
  'screen',
  'tmux',
  'htop',
  'tcpdump',
  'strace',
  'fuel-misc',
  'man-db',
]

cloud_init_services = [
  'cloud-config',
  'cloud-final',
  'cloud-init',
  'cloud-init-container',
  'cloud-init-local',
  'cloud-init-nonet',
  'cloud-log-shutdown',
]

puppet = Noop.hiera('puppet')

describe manifest do
  shared_examples 'catalog' do
    it "should contain ssh host keygen exec for Debian OS only" do
      if facts[:osfamily] == 'Debian'
        should contain_exec('host-ssh-keygen').with(
          'command' => 'ssh-keygen -A'
        )
      else
        should_not contain_exec('host-ssh-keygen')
      end
    end

    it 'should declare tools classes' do
      should contain_class('osnailyfacter::atop')
      should contain_class('osnailyfacter::ssh')
      should contain_class('osnailyfacter::puppet_pull').with(
        'modules_source'   => puppet['modules'],
        'manifests_source' => puppet['manifests']
      )
    end

    it 'should declare osnailyfacter::acpid on virtual machines' do
      facts[:virtual] = 'kvm'
      should contain_class('osnailyfacter::acpid')
    end

    tools.each do |i|
      it do
        should contain_package(i).with({
          'ensure' => 'present'})
      end
    end

    it 'should disable cloud-init services' do
      if facts[:operatingsystem] == 'Ubuntu'
        cloud_init_services.each do |i|
            should contain_service(i).with({
              'enable' => 'false'})
        end
      end
    end

    it do
      should contain_package('cloud-init').with({
        'ensure' => 'absent'})
    end
  end

  test_ubuntu_and_centos manifest
end
