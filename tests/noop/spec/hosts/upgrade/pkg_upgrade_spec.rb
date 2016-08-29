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
    corosync_roles = Noop.hiera('corosync_roles', ['primary-controller', 'controller'])
    corosync_role = Noop.puppet_function 'roles_include', corosync_roles
    apt_opts = [ "-o 'APT::Get::AllowUnauthenticated=1'",
                "-o Dpkg::Options::='--force-confdef'",
                "-o Dpkg::Options::='--force-confold'",
                "-o Dir::etc::sourcelist='-'",
                "-o Dir::Etc::sourceparts='/etc/fuel/maintenance/apt/sources.list.d/'" ].join(" ")

    it { is_expected.to contain_exec('do_upgrade').with(
           :command     => "apt-get dist-upgrade -y --no-remove --force-yes #{apt_opts}",
           :environment => [ 'DEBIAN_FRONTEND=noninteractive' ],
         ) }

    if corosync_role
      it { is_expected.to contain_file('create-policy-rc.d').with(
             :path    => '/usr/sbin/policy-rc.d',
             :content => "#!/bin/bash\n[[ \"\$1\" == \"pacemaker\" ]] && exit 101\n",
             :mode    => '0755',
             :owner   => 'root',
             :group   => 'root',
           ).that_comes_before('Exec[do_upgrade]') }

      it { is_expected.to contain_exec('remove_policy').with(
           :command => "rm -rf /usr/sbin/policy-rc.d",
           :path    => '/bin',
         ).that_requires('Exec[do_upgrade]') }

      it { is_expected.to contain_service('pacemaker').with(
             :ensure => 'running').that_requires('Exec[remove_policy]') }
    end
  end
  test_ubuntu_and_centos manifest
end
