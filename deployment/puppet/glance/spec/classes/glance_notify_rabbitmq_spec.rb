require 'spec_helper'
describe 'glance::notify::rabbitmq' do
  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  let :pre_condition do
    'class { "glance::api": keystone_password => "pass" }'
  end

  describe 'when defaults with rabbit pass specified' do
    let :params do
      {:rabbit_password => 'pass'}
    end
    it { is_expected.to contain_glance_api_config('DEFAULT/notification_driver').with_value('messaging') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_password').with_value('pass') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_password').with_value(params[:rabbit_password]).with_secret(true) }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_userid').with_value('guest') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_host').with_value('localhost') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_port').with_value('5672') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_hosts').with_value('localhost:5672') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value('false') }
    it { is_expected.to contain_glance_api_config('DEFAULT/amqp_durable_queues').with_value('false') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_virtual_host').with_value('/') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_notification_exchange').with_value('glance') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_notification_topic').with_value('notifications') }
  end

  describe 'when passing params and use ssl' do
    let :params do
      {
        :rabbit_password        => 'pass',
        :rabbit_userid          => 'guest2',
        :rabbit_host            => 'localhost2',
        :rabbit_port            => '5673',
        :rabbit_use_ssl         => true,
        :rabbit_durable_queues  => true,
      }
      it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_userid').with_value('guest2') }
      it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_host').with_value('localhost2') }
      it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_port').with_value('5673') }
      it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('true') }
      it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent') }
      it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent') }
      it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent') }
      it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('TLSv1') }
      it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_durable_queues').with_value('true') }
    end
  end

  describe 'with rabbit ssl cert parameters' do
    let :params do
      {
        :rabbit_password        => 'pass',
        :rabbit_use_ssl     => 'true',
        :kombu_ssl_ca_certs => '/etc/ca.cert',
        :kombu_ssl_certfile => '/etc/certfile',
        :kombu_ssl_keyfile  => '/etc/key',
        :kombu_ssl_version  => 'TLSv1',
      }
    end
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value(true) }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_value('/etc/ca.cert') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_value('/etc/certfile') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_value('/etc/key') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('TLSv1') }
  end

  describe 'with rabbit ssl disabled' do
    let :params do
      {
        :rabbit_password    => 'pass',
        :rabbit_use_ssl     => false,
        :kombu_ssl_ca_certs => 'undef',
        :kombu_ssl_certfile => 'undef',
        :kombu_ssl_keyfile  => 'undef',
        :kombu_ssl_version  => 'TLSv1',
      }
    end

    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('false') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/kombu_ssl_version').with_ensure('absent') }
  end

  describe 'when passing params for single rabbit host' do
    let :params do
      {
        :rabbit_password        => 'pass',
        :rabbit_userid          => 'guest2',
        :rabbit_host            => 'localhost2',
        :rabbit_port            => '5673',
        :rabbit_use_ssl         => true,
        :rabbit_durable_queues  => true,
      }
    end
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_userid').with_value('guest2') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_host').with_value('localhost2') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_port').with_value('5673') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_hosts').with_value('localhost2:5673') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('true') }
    it { is_expected.to contain_glance_api_config('DEFAULT/amqp_durable_queues').with_value('true') }
  end

  describe 'when passing params for multiple rabbit hosts' do
    let :params do
      {
        :rabbit_password        => 'pass',
        :rabbit_userid          => 'guest3',
        :rabbit_hosts           => ['nonlocalhost3:5673', 'nonlocalhost4:5673']
      }
    end
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_userid').with_value('guest3') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_hosts').with_value(
                                          'nonlocalhost3:5673,nonlocalhost4:5673') }
    it { is_expected.to contain_glance_api_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value('true') }
    it { is_expected.to_not contain_glance_api_config('oslo_messaging_rabbit/rabbit_port') }
    it { is_expected.to_not contain_glance_api_config('oslo_messaging_rabbit/rabbit_host') }
  end

  describe 'when using deprecated params' do
    let :params do
      {
        :rabbit_durable_queues  => true,
        :rabbit_password        => 'pass'
      }
    end
    it { is_expected.to contain_glance_api_config('DEFAULT/amqp_durable_queues').with_value('true') }
  end
end
