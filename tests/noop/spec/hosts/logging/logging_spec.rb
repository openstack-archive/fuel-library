# ROLE: virt
# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: ironic
# ROLE: controller
# ROLE: compute-vmware
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: ceph-osd
# ROLE: base-os

require 'spec_helper'
require 'shared-examples'
manifest = 'logging/logging.pp'

describe manifest do
  shared_examples 'catalog' do
    it {
      if facts[:operatingsystem] == 'Ubuntu'
        should contain_file('/var/log').with(
          'owner' => 'root',
          'group' => 'syslog',
          'mode'  => '0775'
        )
      else
        should_not contain_file('/var/log')
      end
    }
    if Noop.hiera('role') == 'ironic'
      it {
        should contain_file('/etc/rsyslog.d/70-ironic.conf').with(
          'owner' => 'root',
          'group' => 'syslog',
          'mode'  => '0640',
        )
      }
    end

    it {
      should contain_class('cluster::haproxy::rsyslog')
    }
  end
  test_ubuntu_and_centos manifest
end

