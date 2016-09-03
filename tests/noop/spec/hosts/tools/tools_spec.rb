# ROLE: virt
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
manifest = 'tools/tools.pp'

describe manifest do
  tools = %w(
  screen
  tmux
  htop
  tcpdump
  strace
  fuel-misc
  man-db
  )

  cloud_init_services = %w(
  cloud-config
  cloud-final
  cloud-init
  cloud-init-container
  cloud-init-local
  cloud-init-nonet
  cloud-log-shutdown
  )

  shared_examples 'catalog' do
    atop_hash     = Noop.hiera 'atop', {}
    atop_enabled  = Noop.puppet_function 'pick', atop_hash['service_enabled'], true
    atop_interval = Noop.puppet_function 'pick', atop_hash['interval'], 20
    atop_rotate   = Noop.puppet_function 'pick', atop_hash['rotate'], 7

    puppet = Noop.hiera('puppet')

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
      should contain_class('osnailyfacter::atop').with(
          'service_enabled' => atop_enabled,
          'interval'        => atop_interval,
          'rotate'          => atop_rotate,
      )
      should contain_class('osnailyfacter::ssh').with(
          'accept_env'     => 'LANG LC_*',
      )
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
