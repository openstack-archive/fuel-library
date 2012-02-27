require 'spec_helper'

describe 'swift::proxy' do

  describe 'without memcached being included' do
    it 'should raise an error' do
      expect do
        subject
      end.should raise_error(Puppet::Error)
    end
  end

  # set os so memcache will not fail
  let :facts do
    {:operatingsystem => 'Ubuntu',
     :processorcount  => 1
    }
  end

  let :fixture_dir do
    File.join(File.dirname(__FILE__), '..', 'fixtures')
  end

  describe 'with proper dependencies' do

    let :pre_condition do
      "class { memcached: max_memory => 1}
       class { swift: swift_hash_suffix => string }
       class { 'ssh::server::install': }"
    end

    describe 'with default parameters' do

      let :config_file do
        File.join(fixture_dir, 'default_proxy_server')
      end

      it { should contain_package('swift-proxy').with_ensure('present') }
      it { should_not contain_package('python-swauth') }
      it { should contain_service('swift-proxy').with(
        {:ensure    => 'running',
         :provider  => 'upstart',
         :enable    => true,
         :subscribe => 'File[/etc/swift/proxy-server.conf]'
        }
      )}
      it { should contain_file('/etc/swift/proxy-server.conf').with(
        {:ensure  => 'present',
         :owner   => 'swift',
         :group   => 'swift',
         :mode    => '0660',
         :content => File.read(config_file),
         :require => 'Package[swift-proxy]'
        }
      )}
      # TODO this resource should just be here temporarily until packaging
      # is fixed
      it { should contain_file('/etc/init/swift-proxy.conf') }

    end

    describe 'when using swauth' do

      let :params do
        {:auth_type => 'swauth' }
      end

      describe 'with defaults' do

        let :config_file do
          File.join(fixture_dir, 'swauth_default_proxy_server')
        end

        it { should contain_package('python-swauth').with(
          {:ensure => 'present',
           :before => 'Package[swift-proxy]'
          }
        )}
        it { should contain_file('/etc/swift/proxy-server.conf').with(
          {:content => File.read(config_file)}
        )}
      end

      describe 'with parameter overrides' do

        let :params do
          {:auth_type => 'swauth',
           :swauth_endpoint => '10.0.0.1',
           :swauth_super_admin_key => 'key'
          }
        end
        let :config_file do
          File.join(fixture_dir, 'swauth_overrides_proxy_server')
        end

        it { should contain_file('/etc/swift/proxy-server.conf').with(
          {:content => File.read(config_file)}
        )}

      end

    end

  end

end
