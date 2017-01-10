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
manifest = 'logging/logging.pp'

describe manifest do
  shared_examples 'catalog' do
    base_syslog = Noop.hiera('base_syslog')

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

    it { is_expected.to contain_service('rsyslog') }

    it 'should contain class openstack::logging' do
      is_expected.to contain_class('openstack::logging').with(
        :role               => 'client',
        :show_timezone      => true,
        :log_remote         => true,
        :log_local          => true,
        :log_auth_local     => true,
        :rotation           => 'weekly',
        :keep               => '4',
        :minsize            => '10M',
        :maxsize            => '100M',
        :rservers           => [
          ['remote_type', Noop.puppet_function('pick', base_syslog['syslog_transport'], 'tcp')],
          ['server', base_syslog['syslog_server']],
          ['port', base_syslog['syslog_port']]
        ],
        :virtual            => Noop.puppet_function('str2bool', facts[:is_virtual]),
        :rabbit_fqdn_prefix => Noop.hiera('node_name_prefix_for_messaging', 'messaging-'),
        :rabbit_log_level   => 'NOTICE',
        :debug              => false,
        :ironic_collector   => Noop.puppet_function('roles_include', 'ironic'),
      )
    end

  end
  test_ubuntu_and_centos manifest
end

