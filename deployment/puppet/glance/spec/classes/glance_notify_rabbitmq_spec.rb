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
    it { should contain_glance_api_config('DEFAULT/notification_driver').with_value('messaging') }
    it { should contain_glance_api_config('DEFAULT/rabbit_password').with_value('pass') }
    it { should contain_glance_api_config('DEFAULT/rabbit_userid').with_value('guest') }
    it { should contain_glance_api_config('DEFAULT/rabbit_host').with_value('localhost') }
    it { should contain_glance_api_config('DEFAULT/rabbit_port').with_value('5672') }
    it { should contain_glance_api_config('DEFAULT/rabbit_hosts').with_value('localhost:5672') }
    it { should contain_glance_api_config('DEFAULT/rabbit_ha_queues').with_value('false') }
    it { should contain_glance_api_config('DEFAULT/amqp_durable_queues').with_value('false') }
    it { should contain_glance_api_config('DEFAULT/rabbit_virtual_host').with_value('/') }
    it { should contain_glance_api_config('DEFAULT/rabbit_notification_exchange').with_value('glance') }
    it { should contain_glance_api_config('DEFAULT/rabbit_notification_topic').with_value('notifications') }
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
    it { should contain_glance_api_config('DEFAULT/rabbit_userid').with_value('guest2') }
    it { should contain_glance_api_config('DEFAULT/rabbit_host').with_value('localhost2') }
    it { should contain_glance_api_config('DEFAULT/rabbit_port').with_value('5673') }
    it { should contain_glance_api_config('DEFAULT/rabbit_hosts').with_value('localhost2:5673') }
    it { should contain_glance_api_config('DEFAULT/rabbit_use_ssl').with_value('true') }
    it { should contain_glance_api_config('DEFAULT/amqp_durable_queues').with_value('true') }
  end

  describe 'when passing params for multiple rabbit hosts' do
    let :params do
      {
        :rabbit_password        => 'pass',
        :rabbit_userid          => 'guest3',
        :rabbit_hosts           => ['nonlocalhost3:5673', 'nonlocalhost4:5673']
      }
    end
    it { should contain_glance_api_config('DEFAULT/rabbit_userid').with_value('guest3') }
    it { should contain_glance_api_config('DEFAULT/rabbit_hosts').with_value(
                                          'nonlocalhost3:5673,nonlocalhost4:5673') }
    it { should contain_glance_api_config('DEFAULT/rabbit_ha_queues').with_value('true') }
    it { should_not contain_glance_api_config('DEFAULT/rabbit_port') }
    it { should_not contain_glance_api_config('DEFAULT/rabbit_host') }
  end
end
