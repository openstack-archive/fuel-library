require 'spec_helper'

describe 'nova' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  describe 'with default parameters' do
    it { should contain_package('python').with_ensure('present') }
    it { should contain_package('python-greenlet').with(
      'ensure'  => 'present',
      'require' => 'Package[python]'
    )}
    it { should contain_package('python-nova').with(
      'ensure'  => 'present',
      'require' => 'Package[python-greenlet]'
    )}
    it { should contain_package('nova-common').with(
      'name'   => 'nova-common',
      'ensure' => 'present'
    )}

    it { should contain_group('nova').with(
        'ensure'  => 'present',
        'system'  => true,
        'require' => 'Package[nova-common]'
    )}

    it { should contain_user('nova').with(
        'ensure'  => 'present',
        'gid'     => 'nova',
        'system'  => true,
        'require' => 'Package[nova-common]'
    ) }

    it { should contain_file('/var/log/nova').with(
      'ensure'  => 'directory',
      'mode'    => '0750',
      'owner'   => 'nova',
      'group'   => 'nova',
      'require' => 'Package[nova-common]'
    )}

    it { should contain_file('/etc/nova/nova.conf').with(
      'mode'    => '0640',
      'owner'   => 'nova',
      'group'   => 'nova',
      'require' => 'Package[nova-common]'
    )}

    it { should contain_exec('networking-refresh').with(
      'command'     => '/sbin/ifdown -a ; /sbin/ifup -a',
      'refreshonly' => true
    )}

    it { should_not contain_nova_config('database/connection') }
    it { should_not contain_nova_config('database/idle_timeout').with_value('3600') }

    it { should contain_nova_config('DEFAULT/image_service').with_value('nova.image.glance.GlanceImageService') }
    it { should contain_nova_config('DEFAULT/glance_api_servers').with_value('localhost:9292') }

    it { should contain_nova_config('DEFAULT/auth_strategy').with_value('keystone') }
    it { should_not contain_nova_config('DEFAULT/use_deprecated_auth').with_value(false) }

    it { should contain_nova_config('DEFAULT/rpc_backend').with_value('nova.openstack.common.rpc.impl_kombu') }
    it { should contain_nova_config('DEFAULT/rabbit_host').with_value('localhost') }
    it { should contain_nova_config('DEFAULT/rabbit_password').with_value('guest').with_secret(true) }
    it { should contain_nova_config('DEFAULT/rabbit_port').with_value('5672') }
    it { should contain_nova_config('DEFAULT/rabbit_userid').with_value('guest') }
    it { should contain_nova_config('DEFAULT/rabbit_virtual_host').with_value('/') }

    it { should contain_nova_config('DEFAULT/verbose').with_value(false) }
    it { should contain_nova_config('DEFAULT/debug').with_value(false) }
    it { should contain_nova_config('DEFAULT/logdir').with_value('/var/log/nova') }
    it { should contain_nova_config('DEFAULT/state_path').with_value('/var/lib/nova') }
    it { should contain_nova_config('DEFAULT/lock_path').with_value('/var/lock/nova') }
    it { should contain_nova_config('DEFAULT/service_down_time').with_value('60') }
    it { should contain_nova_config('DEFAULT/rootwrap_config').with_value('/etc/nova/rootwrap.conf') }
    it { should_not contain_nova_config('DEFAULT/notification_driver') }


    describe 'with parameters supplied' do

      let :params do
        {
          'database_connection'      => 'mysql://user:pass@db/db',
          'database_idle_timeout'    => '30',
          'verbose'                  => true,
          'debug'                    => true,
          'logdir'                   => '/var/log/nova2',
          'image_service'            => 'nova.image.local.LocalImageService',
          'rabbit_host'              => 'rabbit',
          'rabbit_userid'            => 'rabbit_user',
          'rabbit_port'              => '5673',
          'rabbit_password'          => 'password',
          'lock_path'                => '/var/locky/path',
          'state_path'               => '/var/lib/nova2',
          'service_down_time'        => '120',
          'auth_strategy'            => 'foo',
          'ensure_package'           => '2012.1.1-15.el6',
          'monitoring_notifications' => true
        }
      end

      it { should contain_package('nova-common').with('ensure' => '2012.1.1-15.el6') }
      it { should contain_package('python-nova').with('ensure' => '2012.1.1-15.el6') }
      it { should contain_nova_config('database/connection').with_value('mysql://user:pass@db/db').with_secret(true) }
      it { should contain_nova_config('database/idle_timeout').with_value('30') }

      it { should contain_nova_config('DEFAULT/image_service').with_value('nova.image.local.LocalImageService') }
      it { should_not contain_nova_config('DEFAULT/glance_api_servers') }

      it { should contain_nova_config('DEFAULT/auth_strategy').with_value('foo') }
      it { should_not contain_nova_config('DEFAULT/use_deprecated_auth').with_value(true) }
      it { should contain_nova_config('DEFAULT/rpc_backend').with_value('nova.openstack.common.rpc.impl_kombu') }
      it { should contain_nova_config('DEFAULT/rabbit_host').with_value('rabbit') }
      it { should contain_nova_config('DEFAULT/rabbit_password').with_value('password').with_secret(true) }
      it { should contain_nova_config('DEFAULT/rabbit_port').with_value('5673') }
      it { should contain_nova_config('DEFAULT/rabbit_userid').with_value('rabbit_user') }
      it { should contain_nova_config('DEFAULT/rabbit_virtual_host').with_value('/') }

      it { should contain_nova_config('DEFAULT/verbose').with_value(true) }
      it { should contain_nova_config('DEFAULT/debug').with_value(true) }
      it { should contain_nova_config('DEFAULT/logdir').with_value('/var/log/nova2') }
      it { should contain_nova_config('DEFAULT/state_path').with_value('/var/lib/nova2') }
      it { should contain_nova_config('DEFAULT/lock_path').with_value('/var/locky/path') }
      it { should contain_nova_config('DEFAULT/service_down_time').with_value('120') }
      it { should contain_nova_config('DEFAULT/notification_driver').with_value('nova.openstack.common.notifier.rpc_notifier') }

    end

    describe 'with deprecated sql parameters' do

      let :params do
        {
          'sql_connection'   => 'mysql://user:pass@db/db',
          'sql_idle_timeout' => '30'
        }
      end
      it { should contain_nova_config('database/connection').with_value('mysql://user:pass@db/db').with_secret(true) }
      it { should contain_nova_config('database/idle_timeout').with_value('30') }
    end


    describe 'with some others parameters supplied' do

      let :params do
        {
          'rabbit_hosts'        => ['rabbit:5673', 'rabbit2:5674'],
        }
      end

      it { should_not contain_nova_config('DEFAULT/rabbit_host') }
      it { should_not contain_nova_config('DEFAULT/rabbit_port') }
      it { should contain_nova_config('DEFAULT/rabbit_hosts').with_value('rabbit:5673,rabbit2:5674') }
      it { should contain_nova_config('DEFAULT/rabbit_ha_queues').with_value(true) }

    end

    describe 'with one rabbit_hosts supplied' do

      let :params do
        {
          'rabbit_hosts'        => ['rabbit:5673'],
        }
      end

      it { should_not contain_nova_config('DEFAULT/rabbit_host') }
      it { should_not contain_nova_config('DEFAULT/rabbit_port') }
      it { should contain_nova_config('DEFAULT/rabbit_hosts').with_value('rabbit:5673') }
      it { should contain_nova_config('DEFAULT/rabbit_ha_queues').with_value(true) }

    end

    describe 'with memcached parameter supplied' do

      let :params do
        {
          'memcached_servers'        => ['memcached01:11211', 'memcached02:11211'],
        }
      end

      it { should contain_nova_config('DEFAULT/memcached_servers').with_value('memcached01:11211,memcached02:11211') }

    end


    describe 'with qpid rpc supplied' do

      let :params do
        {
          'database_connection'      => 'mysql://user:pass@db/db',
          'database_idle_timeout'    => '30',
          'verbose'             => true,
          'debug'               => true,
          'logdir'              => '/var/log/nova2',
          'image_service'       => 'nova.image.local.LocalImageService',
          'rpc_backend'         => 'nova.openstack.common.rpc.impl_qpid',
          'lock_path'           => '/var/locky/path',
          'state_path'          => '/var/lib/nova2',
          'service_down_time'   => '120',
          'auth_strategy'       => 'foo',
          'ensure_package'      => '2012.1.1-15.el6'
        }
      end

      it { should contain_package('nova-common').with('ensure' => '2012.1.1-15.el6') }
      it { should contain_package('python-nova').with('ensure' => '2012.1.1-15.el6') }
      it { should contain_nova_config('database/connection').with_value('mysql://user:pass@db/db') }
      it { should contain_nova_config('database/idle_timeout').with_value('30') }

      it { should contain_nova_config('DEFAULT/image_service').with_value('nova.image.local.LocalImageService') }
      it { should_not contain_nova_config('DEFAULT/glance_api_servers') }

      it { should contain_nova_config('DEFAULT/auth_strategy').with_value('foo') }
      it { should_not contain_nova_config('DEFAULT/use_deprecated_auth').with_value(true) }
      it { should contain_nova_config('DEFAULT/rpc_backend').with_value('nova.openstack.common.rpc.impl_qpid') }
      it { should contain_nova_config('DEFAULT/qpid_hostname').with_value('localhost') }
      it { should contain_nova_config('DEFAULT/qpid_port').with_value('5672') }
      it { should contain_nova_config('DEFAULT/qpid_username').with_value('guest') }
      it { should contain_nova_config('DEFAULT/qpid_password').with_value('guest').with_secret(true) }
      it { should contain_nova_config('DEFAULT/qpid_reconnect').with_value(true) }
      it { should contain_nova_config('DEFAULT/qpid_reconnect_timeout').with_value('0') }
      it { should contain_nova_config('DEFAULT/qpid_reconnect_limit').with_value('0') }
      it { should contain_nova_config('DEFAULT/qpid_reconnect_interval_min').with_value('0') }
      it { should contain_nova_config('DEFAULT/qpid_reconnect_interval_max').with_value('0') }
      it { should contain_nova_config('DEFAULT/qpid_reconnect_interval').with_value('0') }
      it { should contain_nova_config('DEFAULT/qpid_heartbeat').with_value('60') }
      it { should contain_nova_config('DEFAULT/qpid_protocol').with_value('tcp') }
      it { should contain_nova_config('DEFAULT/qpid_tcp_nodelay').with_value(true) }

      it { should contain_nova_config('DEFAULT/verbose').with_value(true) }
      it { should contain_nova_config('DEFAULT/debug').with_value(true) }
      it { should contain_nova_config('DEFAULT/logdir').with_value('/var/log/nova2') }
      it { should contain_nova_config('DEFAULT/state_path').with_value('/var/lib/nova2') }
      it { should contain_nova_config('DEFAULT/lock_path').with_value('/var/locky/path') }
      it { should contain_nova_config('DEFAULT/service_down_time').with_value('120') }

    end

    describe "When platform is RedHat" do
      let :facts do
        {:osfamily => 'RedHat'}
      end
      it { should contain_package('nova-common').with(
        'name'   => 'openstack-nova-common',
        'ensure' => 'present'
      )}
      it { should contain_nova_config('DEFAULT/rootwrap_config').with_value('/etc/nova/rootwrap.conf') }
    end

    describe 'with syslog disabled' do
      it { should contain_nova_config('DEFAULT/use_syslog').with_value(false) }
    end

    describe 'with syslog enabled' do
      let :params do
        {
          :use_syslog   => 'true',
        }
      end

      it { should contain_nova_config('DEFAULT/use_syslog').with_value(true) }
      it { should contain_nova_config('DEFAULT/syslog_log_facility').with_value('LOG_USER') }
    end

    describe 'with syslog enabled and custom settings' do
      let :params do
        {
          :use_syslog   => 'true',
          :log_facility => 'LOG_LOCAL0'
       }
      end

      it { should contain_nova_config('DEFAULT/use_syslog').with_value(true) }
      it { should contain_nova_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0') }
    end

  end
end
