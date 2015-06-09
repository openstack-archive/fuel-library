require 'spec_helper'

describe 'neutron::client' do

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  context 'on Debian platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'Debian' })
    end

    it { is_expected.to contain_class('neutron::client') }
  end

  context 'on RedHat platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end

    it { is_expected.to contain_class('neutron::client') }
  end
end
