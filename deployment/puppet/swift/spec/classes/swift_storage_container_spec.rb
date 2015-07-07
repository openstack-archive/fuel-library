require 'spec_helper'

describe 'swift::storage::container' do
  let :pre_condition do
    "class { 'swift': swift_hash_suffix => 'foo' }
     class { 'swift::storage': storage_local_net_ip => '10.0.0.1' }"
  end

  let :params do
    { :package_ensure => 'present',
      :enabled        => true,
      :manage_service => true }
  end

  shared_examples_for 'swift-storage-container' do
    [{},
     {:package_ensure => 'latest'}
    ].each do |param_set|
      describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
        before do
          params.merge!(param_set)
        end

        it { is_expected.to contain_swift__storage__generic('container').with_package_ensure(params[:package_ensure]) }
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
          'swift-container'            => 'swift-container',
          'swift-container-replicator' => 'swift-container-replicator',
          'swift-container-updater'    => 'swift-container-updater',
          'swift-container-auditor'    => 'swift-container-auditor'
        }
      }
    end

    it_configures 'swift-storage-container'

    context 'Ubuntu specific resources' do
      it 'configures sync' do
        is_expected.to contain_service('swift-container-sync').with(
          :ensure   => 'running',
          :enable   => true,
          :provider => 'upstart',
          :require  => ['File[/etc/init/swift-container-sync.conf]', 'File[/etc/init.d/swift-container-sync]']
        )
        is_expected.to contain_file('/etc/init/swift-container-sync.conf').with(
          :source  => 'puppet:///modules/swift/swift-container-sync.conf.upstart',
          :require => 'Package[swift-container]'
        )
        is_expected.to contain_file('/etc/init.d/swift-container-sync').with(
          :ensure => 'link',
          :target => '/lib/init/upstart-job'
        )
      end
    end
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat' }
    end

    let :platform_params do
      { :service_names => {
          'swift-container'            => 'openstack-swift-container',
          'swift-container-replicator' => 'openstack-swift-container-replicator',
          'swift-container-updater'    => 'openstack-swift-container-updater',
          'swift-container-auditor'    => 'openstack-swift-container-auditor'
        }
      }
    end

    it_configures 'swift-storage-container'

    context 'RedHat specific resources' do
      before do
        params.merge!({ :allowed_sync_hosts => ['127.0.0.1', '10.1.0.1', '10.1.0.2'] })
      end

      let :pre_condition do
         "class { 'swift': swift_hash_suffix => 'foo' }
         class { 'swift::storage::all': storage_local_net_ip => '10.0.0.1' }"
      end

      let :fragment_file do
        "/var/lib/puppet/concat/_etc_swift_container-server.conf/fragments/00_swift-container-6001"
      end

      it {
        is_expected.to contain_file(fragment_file).with_content(/^allowed_sync_hosts = 127.0.0.1,10.1.0.1,10.1.0.2$/)
      }
    end
  end
end
