require 'spec_helper'

describe 'glance::policy' do

  shared_examples_for 'glance policies' do
    let :params do
      {
        :policy_path => '/etc/glance/policy.json',
        :policies    => {
          'context_is_admin' => {
            'key'   => 'context_is_admin',
            'value' => 'foo:bar'
          }
        }
      }
    end

    it 'set up the policies' do
      should contain_openstacklib__policy__base('context_is_admin').with({
        :key   => 'context_is_admin',
        :value => 'foo:bar'
      })
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'glance policies'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'glance policies'
  end
end
