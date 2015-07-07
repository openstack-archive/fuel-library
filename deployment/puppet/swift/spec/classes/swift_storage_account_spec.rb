require 'spec_helper'

describe 'swift::storage::account' do
  let :pre_condition do
     "class { 'swift': swift_hash_suffix => 'foo' }
     class { 'swift::storage': storage_local_net_ip => '10.0.0.1' }"
  end

  let :params do
    { :package_ensure => 'present',
      :enabled        => true,
      :manage_service => true }
  end

  shared_examples_for 'swift-storage-account' do

    [{},
     {:package_ensure => 'latest'}
    ].each do |param_set|
      describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
        before do
          params.merge!(param_set)
        end

        it { is_expected.to contain_swift__storage__generic('account').with_package_ensure(params[:package_ensure]) }
      end
    end

    [{ :enabled => true, :manage_service => true },
     { :enabled => false, :manage_service => true }].each do |param_hash|
      context "when service is_expected.to be #{param_hash[:enabled] ? 'enabled' : 'disabled'}" do
        before do
          params.merge!(param_hash)
        end

        it 'configures services' do
          platform_params[:service_names].each do |service_alias, service_name|
            is_expected.to contain_service(service_alias).with(
              :name    => service_name,
              :ensure  => (param_hash[:manage_service] && param_hash[:enabled]) ? 'running' : 'stopped',
              :enable  => param_hash[:enabled]
            )
          end
        end
      end
    end

    context 'with disabled service managing' do
      before do
        params.merge!({
          :manage_service => false,
          :enabled        => false })
      end

      it 'configures services' do
        platform_params[:service_names].each do |service_alias, service_name|
          is_expected.to contain_service(service_alias).with(
            :ensure    => nil,
            :name      => service_name,
            :enable    => false
          )
        end
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      {:operatingsystem => 'Ubuntu',
       :osfamily        => 'Debian' }

    end

    let :platform_params do
      { :service_names => {
          'swift-account'            => 'swift-account',
          'swift-account-replicator' => 'swift-account-replicator',
          'swift-account-reaper'     => 'swift-account-reaper',
          'swift-account-auditor'    => 'swift-account-auditor'
        }
      }
    end

    it_configures 'swift-storage-account'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat' }
    end

    let :platform_params do
      { :service_names => {
          'swift-account'            => 'openstack-swift-account',
          'swift-account-replicator' => 'openstack-swift-account-replicator',
          'swift-account-reaper'     => 'openstack-swift-account-reaper',
          'swift-account-auditor'    => 'openstack-swift-account-auditor'
        }
      }
    end

    it_configures 'swift-storage-account'
  end
end
