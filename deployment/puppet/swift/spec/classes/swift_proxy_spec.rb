require 'spec_helper'

describe 'swift::proxy' do

  describe 'without memcached being included' do
    it 'should raise an error' do
      expect { catalogue }.to raise_error(Puppet::Error)
    end
  end

  # set os so memcache will not fail
  let :facts do
    {:operatingsystem => 'Ubuntu',
     :osfamily        => 'Debian',
     :processorcount  => 1
    }
  end

  let :fragment_path do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/00_swift_proxy"
  end

  describe 'with proper dependencies' do

    let :pre_condition do
      "class { memcached: max_memory => 1}
       class { swift: swift_hash_suffix => string }"
    end

    describe 'without the proxy local network ip address being specified' do
      it_raises 'a Puppet::Error', /Must pass proxy_local_net_ip/
    end

    describe 'when proxy_local_net_ip is set' do

      let :params do
        {:proxy_local_net_ip => '127.0.0.1'}
      end

      it { is_expected.to contain_service('swift-proxy').with(
        {:ensure    => 'running',
         :provider  => 'upstart',
         :enable    => true,
         :hasstatus => true,
         :subscribe => 'Concat[/etc/swift/proxy-server.conf]',
         :tag       => 'swift-service',
        }
      )}
      it { is_expected.to contain_file('/etc/swift/proxy-server.conf').with(
        {:ensure  => 'present',
         :owner   => 'swift',
         :group   => 'swift',
         :mode    => '0660',
        }
      )}

      it 'should build the header file with all of the default contents' do
        verify_contents(catalogue, fragment_path,
          [
            '[DEFAULT]',
            'bind_port = 8080',
            "workers = #{facts[:processorcount]}",
            'user = swift',
            'log_name = proxy-server',
            'log_level = INFO',
            'log_headers = False',
            'log_address = /dev/log',
            '[pipeline:main]',
            'pipeline = healthcheck cache tempauth proxy-server',
            '[app:proxy-server]',
            'use = egg:swift#proxy',
            'set log_name = proxy-server',
            'set log_facility = LOG_LOCAL1',
            'set log_level = INFO',
            'set log_address = /dev/log',
            'log_handoffs = true',
            'allow_account_management = true',
            'account_autocreate = true'
          ]
        )
      end
      it { is_expected.to contain_concat__fragment('swift_proxy').with_before(
        [
          'Class[Swift::Proxy::Healthcheck]',
          'Class[Swift::Proxy::Cache]',
          'Class[Swift::Proxy::Tempauth]'
        ]
      )}

      describe 'when more parameters are set' do
        let :params do
          {
           :proxy_local_net_ip        => '10.0.0.2',
           :port                      => '80',
           :workers                   => 3,
           :pipeline                  => ['swauth', 'proxy-server'],
           :allow_account_management  => false,
           :account_autocreate        => false,
           :log_level                 => 'DEBUG',
           :log_name                  => 'swift-proxy-server',
           :read_affinity             => 'r1z1=100, r1=200',
           :write_affinity            => 'r1',
           :write_affinity_node_count => '2 * replicas',
           :node_timeout              => '20',
          }
        end
        it 'should build the header file with provided values' do
          verify_contents(catalogue, fragment_path,
            [
              '[DEFAULT]',
              'bind_port = 80',
              "workers = 3",
              'user = swift',
              'log_level = DEBUG',
              '[pipeline:main]',
              'pipeline = swauth proxy-server',
              '[app:proxy-server]',
              'use = egg:swift#proxy',
              'set log_name = swift-proxy-server',
              'allow_account_management = false',
              'account_autocreate = false',
              'read_affinity = r1z1=100, r1=200',
              'write_affinity = r1',
              'write_affinity_node_count = 2 * replicas',
              'node_timeout = 20'
            ]
          )
        end
        if Puppet.version.to_f < 4.0
          it { is_expected.to contain_concat__fragment('swift_proxy').with_before('Class[Swift::Proxy::Swauth]')}
        else
          it { is_expected.to contain_concat__fragment('swift_proxy').with_before(['Class[Swift::Proxy::Swauth]'])}
        end
       end
      describe "when log udp port is set" do
        context 'and log_udp_host is not set' do
          let :params do
            {
             :proxy_local_net_ip        => '10.0.0.2',
             :port                      => '80',
             :workers                   => 3,
             :pipeline                  => ['swauth', 'proxy-server'],
             :allow_account_management  => false,
             :account_autocreate        => false,
             :log_level                 => 'DEBUG',
             :log_name                  => 'swift-proxy-server',
             :log_udp_port              => '514',
             :read_affinity             => 'r1z1=100, r1=200',
             :write_affinity            => 'r1',
             :write_affinity_node_count => '2 * replicas',
             :node_timeout              => '20',
          }
          end
        it_raises 'a Puppet::Error', /log_udp_port requires log_udp_host to be set/
        end
        context 'and log_udp_host is set' do
          let :params do
            {
             :proxy_local_net_ip        => '10.0.0.2',
             :port                      => '80',
             :workers                   => 3,
             :pipeline                  => ['swauth', 'proxy-server'],
             :allow_account_management  => false,
             :account_autocreate        => false,
             :log_level                 => 'DEBUG',
             :log_name                  => 'swift-proxy-server',
             :log_udp_host              => '127.0.0.1',
             :log_udp_port              => '514',
             :read_affinity             => 'r1z1=100, r1=200',
             :write_affinity            => 'r1',
             :write_affinity_node_count => '2 * replicas',
             :node_timeout              => '20',
          }
          end
        it 'should build the header file with provided values' do
          verify_contents(catalogue, fragment_path,
            [
              '[DEFAULT]',
              'bind_port = 80',
              "workers = 3",
              'user = swift',
              'log_level = DEBUG',
              'log_udp_host = 127.0.0.1',
              'log_udp_port = 514',
              '[pipeline:main]',
              'pipeline = swauth proxy-server',
              '[app:proxy-server]',
              'use = egg:swift#proxy',
              'set log_name = swift-proxy-server',
              'allow_account_management = false',
              'account_autocreate = false',
              'read_affinity = r1z1=100, r1=200',
              'write_affinity = r1',
              'write_affinity_node_count = 2 * replicas',
              'node_timeout = 20'
            ]
          )
        end
      end
    end

      describe 'when supplying bad values for parameters' do
        [:account_autocreate, :allow_account_management].each do |param|
          it "should fail when #{param} is not passed a boolean" do
            params[param] = 'false'
            expect { catalogue }.to raise_error(Puppet::Error, /is not a boolean/)
          end
        end

        let :params do
          {
           :proxy_local_net_ip        => '127.0.0.1',
           :write_affinity_node_count => '2 * replicas'
          }
        end

        it "should fail if write_affinity_node_count is used without write_affinity" do
          expect { catalogue }.to raise_error(Puppet::Error, /write_affinity_node_count requires write_affinity/)
        end
      end
    end
  end

  shared_examples_for 'swift-proxy' do
    let :params do
      { :proxy_local_net_ip => '127.0.0.1' }
    end

    [{ :enabled => true, :manage_service => true },
     { :enabled => false, :manage_service => true }].each do |param_hash|
      context "when service is_expected.to be #{param_hash[:enabled] ? 'enabled' : 'disabled'}" do
        before do
          params.merge!(param_hash)
        end

        it 'configures swift-proxy service' do
          is_expected.to contain_service('swift-proxy').with(
            :ensure    => (param_hash[:manage_service] && param_hash[:enabled]) ? 'running' : 'stopped',
            :name      => platform_params[:service_name],
            :provider  => platform_params[:service_provider],
            :enable    => param_hash[:enabled],
            :hasstatus => true,
            :subscribe => 'Concat[/etc/swift/proxy-server.conf]'
          )
        end
      end
    end

    context 'with disabled service managing' do
      before do
        params.merge!({
          :manage_service => false,
          :enabled        => false })
      end

      it 'configures swift-proxy service' do
        is_expected.to contain_service('swift-proxy').with(
          :ensure    => nil,
          :name      => platform_params[:service_name],
          :provider  => platform_params[:service_provider],
          :enable    => false,
          :hasstatus => true,
          :subscribe => 'Concat[/etc/swift/proxy-server.conf]'
        )
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :operatingsystem => 'Ubuntu',
        :osfamily        => 'Debian',
        :concat_basedir  => '/var/lib/puppet/concat' }
    end

    let :platform_params do
      { :service_name     => 'swift-proxy',
        :service_provider => 'upstart' }
    end

    it_configures 'swift-proxy'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :concat_basedir  => '/var/lib/puppet/concat' }
    end

    let :platform_params do
      { :service_name     => 'openstack-swift-proxy',
        :service_provider => nil }
    end

    it_configures 'swift-proxy'
  end
end
