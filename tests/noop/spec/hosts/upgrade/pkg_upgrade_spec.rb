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

manifest = 'upgrade/pkg_upgrade.pp'

describe manifest do

  shared_examples 'catalog' do
    # stub function output, for details see:
    # https://github.com/rodjek/rspec-puppet#accessing-the-parser-scope-where-the-function-is-running
    before do
      Puppet::Parser::Functions.newfunction(:get_packages_for_upgrade, :arity => 1, :type => :rvalue) { |args|
        return { 'pacemaker' => { 'ensure' => 'latest' } }
      }
    end

    corosync_role = Noop.puppet_function 'roles_include', ['primary-controller', 'controller']
    if corosync_role
      it { is_expected.to contain_package('pacemaker').with(:ensure => 'latest') }
      it { is_expected.to contain_file('create-policy-rc.d').with(
             :path    => '/usr/sbin/policy-rc.d',
             :content => "#!/bin/bash\n[[ \"\$1\" =~ \"pacemaker\" ]] && exit 101\n",
             :mode    => '0755',
             :owner   => 'root',
             :group   => 'root',
           ).that_comes_before('Package[pacemaker]') }

      it { is_expected.to contain_exec('remove_policy').with(
           :command => "rm -rf /usr/sbin/policy-rc.d",
           :path    => '/bin',
         ).that_requires('Package[pacemaker]') }

      it { is_expected.to contain_service('pacemaker').with(
             :ensure => 'running').that_requires('Exec[remove_policy]') }
    else
      it { is_expected.to_not contain_file('create-policy-rc.d') }
      it { is_expected.to_not contain_service('pacemaker') }
    end
  end
  test_ubuntu_and_centos manifest
end
