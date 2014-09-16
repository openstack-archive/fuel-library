require 'spec_helper'

describe 'openssl' do
  context 'when on Debian' do
    let (:facts) { {
      :operatingsystem => 'Debian',
      :osfamily        => 'Debian',
    } }

    it { should contain_package('openssl').with_ensure('present') }
    it { should contain_package('ca-certificates').with_ensure('present') }
    it { should contain_exec('update-ca-certificates').with_refreshonly('true') }

    it { should contain_file('ca-certificates.crt').with(
        :ensure => 'present',
        :owner  => 'root',
        :mode   => '0644',
        :path   => '/etc/ssl/certs/ca-certificates.crt'
      )
    }
  end

  context 'when on RedHat' do
    let (:facts) { {
      :lsbmajdistrelease => '6',
      :operatingsystem   => 'RedHat',
      :osfamily          => 'RedHat',
    } }

    it { should contain_package('openssl').with_ensure('present') }
    it { should_not contain_package('ca-certificates') }
    it { should_not contain_exec('update-ca-certificates') }

    it { should contain_file('ca-certificates.crt').with(
        :ensure => 'present',
        :owner  => 'root',
        :mode   => '0644',
        :path   => '/etc/pki/tls/certs/ca-bundle.crt'
      )
    }
  end
end
