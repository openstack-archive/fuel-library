require 'spec_helper'

describe 'nova' do

  shared_examples 'nova' do

    context 'with default parameters' do

      it 'installs packages' do
        should contain_package('python').with_ensure('present')
        should contain_package('python-greenlet').with(
          :ensure  => 'present',
          :require => 'Package[python]'
        )
        should contain_package('python-nova').with(
          :ensure  => 'present',
          :require => 'Package[python-greenlet]'
        )
        should contain_package('nova-common').with(
          :name    => platform_params[:nova_common_package],
          :ensure  => 'present'
        )
      end

      it 'creates user and group' do
        should contain_group('nova').with(
          :ensure  => 'present',
          :system  => true,
          :before  => 'User[nova]'
        )
        should contain_user('nova').with(
          :ensure     => 'present',
          :system     => true,
          :groups     => 'nova',
          :home       => '/var/lib/nova',
          :managehome => false,
          :shell      => '/bin/false'
        )
      end

      it 'creates various files and folders' do
        should contain_file('/var/log/nova').with(
          :ensure  => 'directory',
          :mode    => '0750',
          :owner   => 'nova',
          :group   => 'nova',
          :require => 'Package[nova-common]'
        )
        should contain_file('/etc/nova/nova.conf').with(
          :mode    => '0640',
          :owner   => 'nova',
          :group   => 'nova',
          :require => 'Package[nova-common]'
        )
      end

      it 'configures rootwrap' do
        should contain_nova_config('DEFAULT/rootwrap_config').with_value('/etc/nova/rootwrap.conf')
      end

      it { should contain_exec('networking-refresh').with(
        :command     => '/sbin/ifdown -a ; /sbin/ifup -a',
        :refreshonly => true
      )}

      it 'configures database' do
        should_not contain_nova_config('database/connection')
        should_not contain_nova_config('database/idle_timeout').with_value('3600')
      end

      it 'configures image service' do
        should contain_nova_config('DEFAULT/image_service').with_value('nova.image.glance.GlanceImageService')
        should contain_nova_config('DEFAULT/glance_api_servers').with_value('localhost:9292')
      end

      it 'configures auth_strategy' do
        should contain_nova_config('DEFAULT/auth_strategy').with_value('keystone')
        should_not contain_nova_config('DEFAULT/use_deprecated_auth').with_value(false)
      end

      it 'configures rabbit' do
        should contain_nova_config('DEFAULT/rpc_backend').with_value('nova.openstack.common.rpc.impl_kombu')
        should contain_nova_config('DEFAULT/rabbit_host').with_value('localhost')
        should contain_nova_config('DEFAULT/rabbit_password').with_value('guest').with_secret(true)
        should contain_nova_config('DEFAULT/rabbit_port').with_value('5672')
        should contain_nova_config('DEFAULT/rabbit_userid').with_value('guest')
        should contain_nova_config('DEFAULT/rabbit_virtual_host').with_value('/')
      end

      it 'configures various things' do
        should contain_nova_config('DEFAULT/verbose').with_value(false)
        should contain_nova_config('DEFAULT/debug').with_value(false)
        should contain_nova_config('DEFAULT/log_dir').with_value('/var/log/nova')
        should contain_nova_config('DEFAULT/state_path').with_value('/var/lib/nova')
        should contain_nova_config('DEFAULT/lock_path').with_value(platform_params[:lock_path])
        should contain_nova_config('DEFAULT/service_down_time').with_value('60')
        should contain_nova_config('DEFAULT/rootwrap_config').with_value('/etc/nova/rootwrap.conf')
        should contain_nova_config('DEFAULT/report_interval').with_value('10')
      end

      it 'installs utilities' do
        should contain_class('nova::utilities')
      end

      it 'disables syslog' do
        should contain_nova_config('DEFAULT/use_syslog').with_value(false)
      end
    end

    context 'with overridden parameters' do

      let :params do
        { :database_connection      => 'mysql://user:pass@db/db',
          :database_idle_timeout    => '30',
          :verbose                  => true,
          :debug                    => true,
          :log_dir                  => '/var/log/nova2',
          :image_service            => 'nova.image.local.LocalImageService',
          :rabbit_host              => 'rabbit',
          :rabbit_userid            => 'rabbit_user',
          :rabbit_port              => '5673',
          :rabbit_password          => 'password',
          :lock_path                => '/var/locky/path',
          :state_path               => '/var/lib/nova2',
          :service_down_time        => '120',
          :auth_strategy            => 'foo',
          :ensure_package           => '2012.1.1-15.el6',
          :memcached_servers        => ['memcached01:11211', 'memcached02:11211'],
          :install_utilities        => false,
          :notification_driver      => 'ceilometer.compute.nova_notifier',
          :notification_topics      => 'openstack',
          :notify_api_faults        => true,
          :nova_user_id             => '499',
          :nova_group_id            => '499',
          :report_interval          => '60',
          :nova_shell               => '/bin/bash' }
      end

      it 'creates user and group' do
        should contain_group('nova').with(
          :ensure  => 'present',
          :system  => true,
          :gid     => '499',
          :before  => 'User[nova]'
        )
        should contain_user('nova').with(
          :ensure     => 'present',
          :system     => true,
          :groups     => 'nova',
          :home       => '/var/lib/nova',
          :managehome => false,
          :shell      => '/bin/bash',
          :uid        => '499',
          :gid        => '499'
        )
      end

      it 'installs packages' do
        should contain_package('nova-common').with('ensure' => '2012.1.1-15.el6')
        should contain_package('python-nova').with('ensure' => '2012.1.1-15.el6')
      end

      it 'configures database' do
        should contain_nova_config('database/connection').with_value('mysql://user:pass@db/db').with_secret(true)
        should contain_nova_config('database/idle_timeout').with_value('30')
      end

      it 'configures image service' do
        should contain_nova_config('DEFAULT/image_service').with_value('nova.image.local.LocalImageService')
        should_not contain_nova_config('DEFAULT/glance_api_servers')
      end

      it 'configures auth_strategy' do
        should contain_nova_config('DEFAULT/auth_strategy').with_value('foo')
        should_not contain_nova_config('DEFAULT/use_deprecated_auth').with_value(true)
      end

      it 'configures rabbit' do
        should contain_nova_config('DEFAULT/rpc_backend').with_value('nova.openstack.common.rpc.impl_kombu')
        should contain_nova_config('DEFAULT/rabbit_host').with_value('rabbit')
        should contain_nova_config('DEFAULT/rabbit_password').with_value('password').with_secret(true)
        should contain_nova_config('DEFAULT/rabbit_port').with_value('5673')
        should contain_nova_config('DEFAULT/rabbit_userid').with_value('rabbit_user')
        should contain_nova_config('DEFAULT/rabbit_virtual_host').with_value('/')
      end

      it 'configures memcached_servers' do
        should contain_nova_config('DEFAULT/memcached_servers').with_value('memcached01:11211,memcached02:11211')
      end

      it 'configures various things' do
        should contain_nova_config('DEFAULT/verbose').with_value(true)
        should contain_nova_config('DEFAULT/debug').with_value(true)
        should contain_nova_config('DEFAULT/log_dir').with_value('/var/log/nova2')
        should contain_nova_config('DEFAULT/state_path').with_value('/var/lib/nova2')
        should contain_nova_config('DEFAULT/lock_path').with_value('/var/locky/path')
        should contain_nova_config('DEFAULT/service_down_time').with_value('120')
        should contain_nova_config('DEFAULT/notification_driver').with_value('ceilometer.compute.nova_notifier')
        should contain_nova_config('DEFAULT/notification_topics').with_value('openstack')
        should contain_nova_config('DEFAULT/notify_api_faults').with_value(true)
        should contain_nova_config('DEFAULT/report_interval').with_value('60')
      end

      context 'with multiple notification_driver' do
        before { params.merge!( :notification_driver => ['ceilometer.compute.nova_notifier', 'nova.openstack.common.notifier.rpc_notifier']) }

        it { should contain_nova_config('DEFAULT/notification_driver').with_value(
          'ceilometer.compute.nova_notifier,nova.openstack.common.notifier.rpc_notifier'
        ) }
      end

      it 'does not install utilities' do
        should_not contain_class('nova::utilities')
      end

      context 'with logging directory disabled' do
        before { params.merge!( :log_dir => false) }

        it { should contain_nova_config('DEFAULT/log_dir').with_ensure('absent') }
      end
    end

    context 'with wrong notify_on_state_change parameter' do
      let :params do
        { :notify_on_state_change => 'vm_status' }
      end

      it 'configures database' do
        should contain_nova_config('DEFAULT/notify_on_state_change').with_ensure('absent')
      end
    end

    context 'with notify_on_state_change parameter' do
      let :params do
        { :notify_on_state_change => 'vm_state' }
      end

      it 'configures database' do
        should contain_nova_config('DEFAULT/notify_on_state_change').with_value('vm_state')
      end
    end

    context 'with deprecated sql parameters' do
      let :params do
        { :sql_connection   => 'mysql://user:pass@db/db',
          :sql_idle_timeout => '30' }
      end

      it 'configures database' do
        should contain_nova_config('database/connection').with_value('mysql://user:pass@db/db').with_secret(true)
        should contain_nova_config('database/idle_timeout').with_value('30')
      end
    end

    context 'with syslog enabled' do
      let :params do
        { :use_syslog => 'true' }
      end

      it 'configures syslog' do
        should contain_nova_config('DEFAULT/use_syslog').with_value(true)
        should contain_nova_config('DEFAULT/syslog_log_facility').with_value('LOG_USER')
      end
    end

    context 'with syslog enabled and log_facility parameter' do
      let :params do
        { :use_syslog   => 'true',
          :log_facility => 'LOG_LOCAL0' }
      end

      it 'configures syslog' do
        should contain_nova_config('DEFAULT/use_syslog').with_value(true)
        should contain_nova_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0')
      end
    end

    context 'with rabbit_hosts parameter' do
      let :params do
        { :rabbit_hosts => ['rabbit:5673', 'rabbit2:5674'] }
      end

      it 'configures rabbit' do
        should_not contain_nova_config('DEFAULT/rabbit_host')
        should_not contain_nova_config('DEFAULT/rabbit_port')
        should contain_nova_config('DEFAULT/rabbit_hosts').with_value('rabbit:5673,rabbit2:5674')
        should contain_nova_config('DEFAULT/rabbit_ha_queues').with_value(true)
        should contain_nova_config('DEFAULT/rabbit_use_ssl').with_value(false)
        should contain_nova_config('DEFAULT/amqp_durable_queues').with_value(false)
        should contain_nova_config('DEFAULT/kombu_ssl_ca_certs').with_ensure('absent')
        should contain_nova_config('DEFAULT/kombu_ssl_certfile').with_ensure('absent')
        should contain_nova_config('DEFAULT/kombu_ssl_keyfile').with_ensure('absent')
        should contain_nova_config('DEFAULT/kombu_ssl_version').with_ensure('absent')
      end
    end

    context 'with rabbit_hosts parameter (one server)' do
      let :params do
        { :rabbit_hosts => ['rabbit:5673'] }
      end

      it 'configures rabbit' do
        should_not contain_nova_config('DEFAULT/rabbit_host')
        should_not contain_nova_config('DEFAULT/rabbit_port')
        should contain_nova_config('DEFAULT/rabbit_hosts').with_value('rabbit:5673')
        should contain_nova_config('DEFAULT/rabbit_ha_queues').with_value(true)
        should contain_nova_config('DEFAULT/rabbit_use_ssl').with_value(false)
        should contain_nova_config('DEFAULT/amqp_durable_queues').with_value(false)
      end
    end

    context 'with amqp_durable_queues parameter' do
      let :params do
        { :rabbit_hosts => ['rabbit:5673'],
          :amqp_durable_queues => 'true' }
      end

      it 'configures rabbit' do
        should_not contain_nova_config('DEFAULT/rabbit_host')
        should_not contain_nova_config('DEFAULT/rabbit_port')
        should contain_nova_config('DEFAULT/rabbit_hosts').with_value('rabbit:5673')
        should contain_nova_config('DEFAULT/rabbit_ha_queues').with_value(true)
        should contain_nova_config('DEFAULT/rabbit_use_ssl').with_value(false)
        should contain_nova_config('DEFAULT/amqp_durable_queues').with_value(true)
        should contain_nova_config('DEFAULT/kombu_ssl_ca_certs').with_ensure('absent')
        should contain_nova_config('DEFAULT/kombu_ssl_certfile').with_ensure('absent')
        should contain_nova_config('DEFAULT/kombu_ssl_keyfile').with_ensure('absent')
        should contain_nova_config('DEFAULT/kombu_ssl_version').with_ensure('absent')
      end
    end

    context 'with rabbit_use_ssl parameter' do
      let :params do
        { :rabbit_hosts   => ['rabbit:5673'],
          :rabbit_use_ssl => 'true' }
      end

      it 'configures rabbit' do
        should_not contain_nova_config('DEFAULT/rabbit_host')
        should_not contain_nova_config('DEFAULT/rabbit_port')
        should contain_nova_config('DEFAULT/rabbit_hosts').with_value('rabbit:5673')
        should contain_nova_config('DEFAULT/rabbit_ha_queues').with_value(true)
        should contain_nova_config('DEFAULT/rabbit_use_ssl').with_value(true)
        should contain_nova_config('DEFAULT/amqp_durable_queues').with_value(false)
        should contain_nova_config('DEFAULT/kombu_ssl_ca_certs').with_ensure('absent')
        should contain_nova_config('DEFAULT/kombu_ssl_certfile').with_ensure('absent')
        should contain_nova_config('DEFAULT/kombu_ssl_keyfile').with_ensure('absent')
        should contain_nova_config('DEFAULT/kombu_ssl_version').with_value('SSLv3')
      end
    end

    context 'with amqp ssl parameters' do
      let :params do
        { :rabbit_hosts       => ['rabbit:5673'],
          :rabbit_use_ssl     => 'true',
          :kombu_ssl_ca_certs => '/etc/ca.cert',
          :kombu_ssl_certfile => '/etc/certfile',
          :kombu_ssl_keyfile  => '/etc/key',
          :kombu_ssl_version  => 'TLSv1', }
      end

      it 'configures rabbit' do
        should contain_nova_config('DEFAULT/rabbit_use_ssl').with_value(true)
        should contain_nova_config('DEFAULT/kombu_ssl_ca_certs').with_value('/etc/ca.cert')
        should contain_nova_config('DEFAULT/kombu_ssl_certfile').with_value('/etc/certfile')
        should contain_nova_config('DEFAULT/kombu_ssl_keyfile').with_value('/etc/key')
        should contain_nova_config('DEFAULT/kombu_ssl_version').with_value('TLSv1')
      end
    end

    context 'with qpid rpc_backend' do
      let :params do
        { :rpc_backend => 'nova.openstack.common.rpc.impl_qpid' }
      end

      context 'with default parameters' do
        it 'configures qpid' do
          should contain_nova_config('DEFAULT/rpc_backend').with_value('nova.openstack.common.rpc.impl_qpid')
          should contain_nova_config('DEFAULT/qpid_hostname').with_value('localhost')
          should contain_nova_config('DEFAULT/qpid_port').with_value('5672')
          should contain_nova_config('DEFAULT/qpid_username').with_value('guest')
          should contain_nova_config('DEFAULT/qpid_password').with_value('guest').with_secret(true)
          should contain_nova_config('DEFAULT/qpid_heartbeat').with_value('60')
          should contain_nova_config('DEFAULT/qpid_protocol').with_value('tcp')
          should contain_nova_config('DEFAULT/qpid_tcp_nodelay').with_value(true)
        end
      end

      context 'with qpid_password parameter (without qpid_sasl_mechanisms)' do
        before do
          params.merge!({ :qpid_password => 'guest' })
        end
        it { should contain_nova_config('DEFAULT/qpid_sasl_mechanisms').with_ensure('absent') }
      end

      context 'with qpid_password parameter (with qpid_sasl_mechanisms)' do
        before do
          params.merge!({
            :qpid_password        => 'guest',
            :qpid_sasl_mechanisms => 'A'
          })
        end
        it { should contain_nova_config('DEFAULT/qpid_sasl_mechanisms').with_value('A') }
      end

      context 'with qpid_password parameter (with array of qpid_sasl_mechanisms)' do
        before do
          params.merge!({
            :qpid_password        => 'guest',
            :qpid_sasl_mechanisms => [ 'DIGEST-MD5', 'GSSAPI', 'PLAIN' ]
          })
        end
        it { should contain_nova_config('DEFAULT/qpid_sasl_mechanisms').with_value('DIGEST-MD5 GSSAPI PLAIN') }
      end
    end

    context 'with ssh public key' do
        let :params do
            {
                :nova_public_key => {'type' => 'ssh-rsa',
                                     'key'  => 'keydata'}
            }
        end

        it 'should install ssh public key' do
            should contain_ssh_authorized_key('nova-migration-public-key').with(
                :ensure => 'present',
                :key => 'keydata',
                :type => 'ssh-rsa'
            )
        end
    end

    context 'with ssh public key missing key type' do
        let :params do
            {
                :nova_public_key => {'type' => '',
                                     'key'  => 'keydata'}
            }
        end

        it 'should raise an error' do
            expect {
                should contain_ssh_authorized_key('nova-migration-public-key').with(
                    :ensure => 'present',
                    :key => 'keydata',
                    :type => ''
                )
            }.to raise_error Puppet::Error, /You must provide both a key type and key data./
        end
    end

    context 'with ssh public key missing key data' do
        let :params do
            {
                :nova_public_key => {'type' => 'ssh-rsa',
                                     'key'  => ''}
            }
        end

        it 'should raise an error' do
            expect {
                should contain_ssh_authorized_key('nova-migration-public-key').with(
                    :ensure => 'present',
                    :key => 'keydata',
                    :type => ''
                )
            }.to raise_error Puppet::Error, /You must provide both a key type and key data./
        end
    end

    context 'with ssh private key' do
        let :params do
            {
                :nova_private_key => {'type' => 'ssh-rsa',
                                     'key'  => 'keydata'}
            }
        end

        it 'should install ssh private key' do
            should contain_file('/var/lib/nova/.ssh/id_rsa').with(
                :content => 'keydata'
            )
        end
    end

    context 'with ssh private key missing key type' do
        let :params do
            {
                :nova_private_key => {'type' => '',
                                     'key'  => 'keydata'}
            }
        end

        it 'should raise an error' do
            expect {
                should contain_file('/var/lib/nova/.ssh/id_rsa').with(
                    :content => 'keydata'
                )
            }.to raise_error Puppet::Error, /You must provide both a key type and key data./
        end
    end

    context 'with ssh private key having incorrect key type' do
        let :params do
            {
                :nova_private_key => {'type' => 'invalid',
                                     'key'  => 'keydata'}
            }
        end

        it 'should raise an error' do
            expect {
                should contain_file('/var/lib/nova/.ssh/id_rsa').with(
                    :content => 'keydata'
                )
            }.to raise_error Puppet::Error, /Unable to determine name of private key file./
        end
    end

    context 'with ssh private key missing key data' do
        let :params do
            {
                :nova_private_key => {'type' => 'ssh-rsa',
                                     'key'  => ''}
            }
        end

        it 'should raise an error' do
            expect {
                should contain_file('/var/lib/nova/.ssh/id_rsa').with(
                    :content => 'keydata'
                )
            }.to raise_error Puppet::Error, /You must provide both a key type and key data./
        end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :nova_common_package => 'nova-common',
        :lock_path           => '/var/lock/nova' }
    end

    it_behaves_like 'nova'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :nova_common_package => 'openstack-nova-common',
        :lock_path           => '/var/lib/nova/tmp' }
    end

    it_behaves_like 'nova'
  end
end
