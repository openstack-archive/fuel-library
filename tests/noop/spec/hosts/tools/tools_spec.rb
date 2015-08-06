require 'spec_helper'
require 'shared-examples'
manifest = 'tools/tools.pp'

tools = [
  'screen',
  'tmux',
  'man',
  'htop',
  'tcpdump',
  'strace',
  'fuel-misc'
]

puppet = Noop.hiera('puppet')

describe manifest do
  shared_examples 'catalog' do
    it 'should declare tools classes' do
      should contain_class('osnailyfacter::acpid')
      should contain_class('osnailyfacter::atop')
      should contain_class('osnailyfacter::ssh')
      should contain_class('puppet::pull').with({'modules_source' => puppet['modules']}, {'manifests_source' => puppet['manifests']})
    end

    tools.each do |i|
      it do
        should contain_package(i).with({
          'ensure' => 'present'})
      end
    end

    it do
      should contain_package('cloud-init').with({
        'ensure' => 'purged'})
    end
  end

  test_ubuntu_and_centos manifest
end
