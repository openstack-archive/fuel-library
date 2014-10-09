require 'spec_helper'

describe 'swift::storage::generic' do

  let :title do
    'account'
  end

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
    {:package_ensure => 'present',
     :service_provider => 'upstart'}
  end

  describe 'with an invalid title' do
    let :title do
      'foo'
    end
    it 'should fail' do
      expect { subject }.to raise_error(Puppet::Error, /does not match/)
    end
  end

  ['account', 'object', 'container'].each do |t|
    [{},
     {:package_ensure => 'latest',
      :service_provider => 'init'}
    ].each do |param_set|
      describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
        let :title do
          t
        end
        let :param_hash do
          default_params.merge(param_set)
        end
        let :params do
          param_set
        end
        it { should contain_package("swift-#{t}").with_ensure(param_hash[:package_ensure]) }
        it { should contain_service("swift-#{t}").with(
          :ensure    => 'running',
          :enable    => true,
          :hasstatus => true,
          :provider  => param_hash[:service_provider]
        )}
        it { should contain_service("swift-#{t}-replicator").with(
          :ensure    => 'running',
          :enable    => true,
          :hasstatus => true,
          :provider  => param_hash[:service_provider]
        )}
        it { should contain_file("/etc/swift/#{t}-server/").with(
          :ensure => 'directory',
          :owner  => 'swift',
          :group  => 'swift'
        )}
      end
      # TODO - I do not want to add tests for the upstart stuff
      # I need to check the tickets and see if this stuff is fixed
    end
  end
end
