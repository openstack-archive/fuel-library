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
     :processorcount  => 1,
     :concat_basedir  => '/var/lib/puppet/concat',
    }
  end

  let :fragment_path do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/00_swift_proxy"
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
         :subscribe => 'Concat[/etc/swift/proxy-server.conf]'
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

      it 'should build the header file with all of the default contents' do
        verify_contents(subject, fragment_path,
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
            'account_autocreate = true'
          ]
        )
      end
      it { should contain_concat__fragment('swift_proxy').with_before(
        [
          'Class[Swift::Proxy::Healthcheck]',
          'Class[Swift::Proxy::Cache]',
          'Class[Swift::Proxy::Tempauth]'
        ]
      )}

      describe 'when more parameters are set' do
        let :params do
          {
           :proxy_local_net_ip => '10.0.0.2',
           :port => '80',
           :workers => 3,
           :pipeline  => ['swauth', 'proxy-server'],
           :allow_account_management => false,
           :account_autocreate => false
          }
        end
        it 'should build the header file with provided values' do
          verify_contents(subject, fragment_path,
            [
              '[DEFAULT]',
              'bind_port = 80',
              "workers = 3",
              'user = swift',
              '[pipeline:main]',
              'pipeline = swauth proxy-server',
              '[app:proxy-server]',
              'use = egg:swift#proxy',
              'allow_account_management = false',
              'account_autocreate = false'
            ]
          )
        end
        it { should contain_concat__fragment('swift_proxy').with_before(
          'Class[Swift::Proxy::Swauth]'
        )}
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

  end
end
