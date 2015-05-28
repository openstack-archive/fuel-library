require 'spec_helper'

describe 'mongodb::server' do
  let :facts do
    {
      :osfamily        => 'Debian',
      :operatingsystem => 'Debian',
    }
  end

  context 'with defaults' do
    it { is_expected.to contain_class('mongodb::server::install') }
    it { is_expected.to contain_class('mongodb::server::config') }
  end

  context 'when deploying on Solaris' do
    let :facts do
      { :osfamily        => 'Solaris' }
    end
    it { expect { is_expected.to raise_error(Puppet::Error) } }
  end

end