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

  let :params do
    {:rabbit_password => 'pass'}
  end

  it { should contain_glance_api_config('DEFAULT/notifier_strategy').with_value('rabbit') }
  it { should contain_glance_api_config('DEFAULT/rabbit_password').with_value('pass') }
  it { should contain_glance_api_config('DEFAULT/rabbit_userid').with_value('guest') }
  it { should contain_glance_api_config('DEFAULT/rabbit_host').with_value('localhost') }

  describe 'when passing params' do
    let :params do
      {
        :rabbit_password => 'pass',
        :rabbit_userid   => 'guest2',
        :rabbit_host     => 'localhost2',
      }
      it { should contain_glance_api_config('DEFAULT/rabbit_userid').with_value('guest2') }
      it { should contain_glance_api_config('DEFAULT/rabbit_host').with_value('localhost2') }
    end
  end
end
