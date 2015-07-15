require 'spec_helper'
describe 'sahara::notify::qpid' do
  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  describe 'when default params and qpid_password' do
    let :params do
      {:qpid_password => 'pass'}
    end

    it { is_expected.to contain_sahara_config('DEFAULT/qpid_username').with_value('guest') }
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_password').with_value('pass') }
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_password').with_value(params[:qpid_password]).with_secret(true) }
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_hostname').with_value('localhost') }
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_port').with_value('5672') }
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_protocol').with_value('tcp') }
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
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_username').with_value('guest2') }
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_hostname').with_value('localhost2') }
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_port').with_value('5673') }
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_protocol').with_value('tcp') }
  end

  describe 'when configuring with ssl' do
    let :params do
      {
        :qpid_password => 'pass3',
        :qpid_username => 'guest3',
        :qpid_hostname => 'localhost3',
        :qpid_port     => '5671',
        :qpid_protocol => 'ssl',
        :kombu_ssl_keyfile => '/srv/sahara_ssl.key',
        :kombu_ssl_certfile => '/srv/sahara_ssl.crt',
        :kombu_ssl_ca_certs => '/srv/cacert',
      }
    end
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_username').with_value('guest3') }
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_hostname').with_value('localhost3') }
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_port').with_value('5671') }
    it { is_expected.to contain_sahara_config('DEFAULT/qpid_protocol').with_value('ssl') }
    it { is_expected.to contain_sahara_config('DEFAULT/kombu_ssl_keyfile').with_value('/srv/sahara_ssl.key') }
    it { is_expected.to contain_sahara_config('DEFAULT/kombu_ssl_certfile').with_value('/srv/sahara_ssl.crt') }
    it { is_expected.to contain_sahara_config('DEFAULT/kombu_ssl_ca_certs').with_value('/srv/cacert') }
  end
end
