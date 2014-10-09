require 'spec_helper'
describe 'swift::storage::container' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian'
    }
  end

  let :pre_condition do
    "class { 'ssh::server::install': }
     class { 'swift': swift_hash_suffix => 'foo' }
     class { 'swift::storage': storage_local_net_ip => '10.0.0.1' }"
  end

  let :default_params do
    {:package_ensure => 'present'}
  end

  [{},
   {:package_ensure => 'latest'}
  ].each do |param_set|
    describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
      let :param_hash do
        default_params.merge(param_set)
      end
      let :params do
        param_set
      end
      it { should contain_swift__storage__generic('container').with_package_ensure(param_hash[:package_ensure]) }
      it 'should have some other services' do
        ['swift-container-updater', 'swift-container-auditor'].each do |service|
          should contain_service(service).with(
            :ensure   => 'running',
            :enable   => true,
            :provider => 'upstart',
            :require  => 'Package[swift-container]'
          )
        end
        should contain_service('swift-container-sync').with(
          :ensure   => 'running',
          :enable   => true,
          :provider => 'upstart',
          :require  => ['File[/etc/init/swift-container-sync.conf]', 'File[/etc/init.d/swift-container-sync]']
        )
        should contain_file('/etc/init/swift-container-sync.conf').with(
          :source  => 'puppet:///modules/swift/swift-container-sync.conf.upstart',
          :require => 'Package[swift-container]'
        )
        should contain_file('/etc/init.d/swift-container-sync').with(
          :ensure => 'link',
          :target => '/lib/init/upstart-job'
        )
      end
    end
  end

  describe 'on rhel' do
    let :facts do
      {
        :operatingsystem => 'RedHat',
        :osfamily        => 'RedHat',
        :concat_basedir => '/var/lib/puppet/concat'
      }
    end
    it 'should have some support services' do
      ['swift-container-updater', 'swift-container-auditor'].each do |service|
        should contain_service(service).with(
          :name     => "openstack-#{service}",
          :ensure   => 'running',
          :enable   => true,
          :require  => 'Package[swift-container]'
        )
      end
    end

    describe 'configuration file' do
      let :pre_condition do
        "class { 'ssh::server::install': }
         class { 'swift': swift_hash_suffix => 'foo' }
         class { 'swift::storage::all': storage_local_net_ip => '10.0.0.1' }"
      end

      let :fragment_file do
        "/var/lib/puppet/concat/_etc_swift_container-server.conf/fragments/00_swift-container-6001"
      end

      it { should contain_file(fragment_file).with_content(/^allowed_sync_hosts = 127.0.0.1$/) }

      describe 'with allowed_sync_hosts' do

        let :params do
          { :allowed_sync_hosts => ['127.0.0.1', '10.1.0.1', '10.1.0.2'], }
        end

        it {
          should contain_file(fragment_file).with_content(/^allowed_sync_hosts = 127.0.0.1,10.1.0.1,10.1.0.2$/)
        }
      end
    end
  end
end
