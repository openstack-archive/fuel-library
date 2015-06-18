require 'spec_helper'
describe 'glance::notify::qpid' do
  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  let :pre_condition do
    'class { "glance::api": keystone_password => "pass" }'
  end

  describe 'when default params and qpid_password' do
    let :params do
      {:qpid_password => 'pass'}
    end

    it { should contain_glance_api_config('DEFAULT/notifier_driver').with_value('qpid') }
    it { should contain_glance_api_config('DEFAULT/qpid_username').with_value('guest') }
    it { should contain_glance_api_config('DEFAULT/qpid_password').with_value('pass') }
    it { should contain_glance_api_config('DEFAULT/qpid_password').with_value(params[:qpid_password]).with_secret(true) }
    it { should contain_glance_api_config('DEFAULT/qpid_hostname').with_value('localhost') }
    it { should contain_glance_api_config('DEFAULT/qpid_port').with_value('5672') }
    it { should contain_glance_api_config('DEFAULT/qpid_protocol').with_value('tcp') }
  end

  describe 'when passing params' do
    let :params do
      {
        :qpid_password => 'pass2',
        :qpid_username => 'guest2',
        :qpid_hostname => 'localhost2',
        :qpid_port     => '5673'
      }
    end
    it { should contain_glance_api_config('DEFAULT/qpid_username').with_value('guest2') }
    it { should contain_glance_api_config('DEFAULT/qpid_hostname').with_value('localhost2') }
    it { should contain_glance_api_config('DEFAULT/qpid_port').with_value('5673') }
    it { should contain_glance_api_config('DEFAULT/qpid_protocol').with_value('tcp') }
  end

  describe 'when configuring with ssl' do
    let :params do
      {
        :qpid_password => 'pass3',
        :qpid_username => 'guest3',
        :qpid_hostname => 'localhost3',
        :qpid_port     => '5671',
        :qpid_protocol => 'ssl'
      }
    end
    it { should contain_glance_api_config('DEFAULT/qpid_username').with_value('guest3') }
    it { should contain_glance_api_config('DEFAULT/qpid_hostname').with_value('localhost3') }
    it { should contain_glance_api_config('DEFAULT/qpid_port').with_value('5671') }
    it { should contain_glance_api_config('DEFAULT/qpid_protocol').with_value('ssl') }
  end
end
