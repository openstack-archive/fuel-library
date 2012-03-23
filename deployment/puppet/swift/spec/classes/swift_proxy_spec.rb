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
     :osfamily        => 'Debian',
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

    describe 'without the proxy local network ip address being specified' do
      it "should fail" do
        expect do
          subject
        end.should raise_error(Puppet::Error, /Must pass proxy_local_net_ip/)
      end
    end

    describe 'when proxy_local_net_ip is set' do

      let :params do
        {:proxy_local_net_ip => '127.0.0.1'}
      end

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
         :require => 'Package[swift-proxy]'
        }
      )}

      it 'should contain default config file' do
        content = param_value(
          subject,
          'file', '/etc/swift/proxy-server.conf',
          'content'
        )
        expected_lines =
        [
          '[DEFAULT]',
          'bind_port = 8080',
          "workers = #{facts[:processorcount]}",
          'user = swift',
          '[pipeline:main]',
          'pipeline = healthcheck cache tempauth proxy-server',
          '[app:proxy-server]',
          'use = egg:swift#proxy',
          'allow_account_management = true',
          'account_autocreate = true',
          '[filter:healthcheck]',
          'use = egg:swift#healthcheck',
          '[filter:cache]',
          'use = egg:swift#memcache',
          'memcache_servers = 127.0.0.1:11211'
        ]
        (content.split("\n") & expected_lines).should =~ expected_lines
      end

      describe 'when more parameters are set' do
        let :params do
          {
           :proxy_local_net_ip => '10.0.0.2',
           :port => '80',
           :workers => 3,
           :cache_servers => ['foo:1', 'bar:2'],
           :allow_account_management => true
          }
        end
        it 'should contain default config file' do
          content = param_value(
            subject,
            'file', '/etc/swift/proxy-server.conf',
            'content'
          )
          expected_lines =
            [
              'bind_port = 80',
              "workers = 3",
              'allow_account_management = true',
              'memcache_servers = foo:1,bar:2'
            ]
          (content.split("\n") & expected_lines).should =~ expected_lines
        end
      end
      # TODO this resource should just be here temporarily until packaging
      # is fixed
      it { should contain_file('/etc/init/swift-proxy.conf') }

      describe 'when using tempauth' do

        it { should_not contain_package('python-swauth') }
        it 'should fail when setting account_autocreate to false' do
          params[:auth_type] = 'tempauth'
          params[:account_autocreate] = false
          expect do
            subject
          end.should raise_error(Puppet::Error, /account_autocreate must be set to true when auth type is tempauth/)
        end
        it 'should contain tempauth configuration' do
          content = param_value(
            subject,
            'file', '/etc/swift/proxy-server.conf',
            'content'
          )
          expected_lines =
          [
          'pipeline = healthcheck cache tempauth proxy-server',
          '[filter:tempauth]',
          'use = egg:swift#tempauth',
          'user_admin_admin = admin .admin .reseller_admin',
          'user_test_tester = testing .admin',
          'user_test2_tester2 = testing2 .admin',
          'user_test_tester3 = testing3'
          ]
          (content.split("\n") & expected_lines).should =~ expected_lines
        end
      end

      describe 'when supplying bad values for parameters' do
        [:account_autocreate, :allow_account_management].each do |param|
          it "should fail when #{param} is not passed a boolean" do
            params[param] = 'false'
            expect do
              subject
            end.should raise_error(Puppet::Error, /is not a boolean/)
          end
        end
      end
    end

    describe 'when using swauth' do

      let :params do
        {:proxy_local_net_ip => '127.0.0.1',
         :auth_type => 'swauth' }
      end

      describe 'with defaults' do

        it { should contain_package('python-swauth').with(
          {:ensure => 'present',
           :before => 'Package[swift-proxy]'
          }
        )}
        it 'should create a config file with default swauth config' do
          content = param_value(
            subject,
            'file', '/etc/swift/proxy-server.conf',
            'content'
          )
          expected_lines =
          [
            '[filter:swauth]',
            'use = egg:swauth#swauth',
            'default_swift_cluster = local#127.0.0.1',
            'super_admin_key = swauthkey'
          ]
          (content.split("\n") & expected_lines).should =~ expected_lines

        end
      end

      describe 'with parameter overrides' do

        let :params do
          {:proxy_local_net_ip => '127.0.0.1',
           :auth_type => 'swauth',
           :swauth_endpoint => '10.0.0.1',
           :swauth_super_admin_key => 'key'
          }
        end

        it 'should create a config file with default swauth config' do
          content = param_value(
            subject,
            'file', '/etc/swift/proxy-server.conf',
            'content'
          )
          expected_lines =
          [
            '[filter:swauth]',
            'use = egg:swauth#swauth',
            'default_swift_cluster = local#10.0.0.1',
            'super_admin_key = key'
          ]
          (content.split("\n") & expected_lines).should =~ expected_lines
        end
      end
    end
  end
end
