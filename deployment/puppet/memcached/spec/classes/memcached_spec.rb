require 'spec_helper'
describe 'memcached' do

  describe 'with manage_firewall parameter' do
    ['Debian','RedHat'].each do |osfam|
      context "on osfamily #{osfam}" do
        let(:facts) do
          { :osfamily       => osfam,
            :memorysize     => '1000 MB',
            :processorcount => '1',
          }
        end

        ['true',true].each do |value|
          context "set to #{value}" do
            let(:params) { { :manage_firewall => value } }

            it { should contain_class('memcached') }

            it { should contain_firewall('100_tcp_11211_for_memcached') }
            it { should contain_firewall('100_udp_11211_for_memcached') }
          end
        end

        ['false',false].each do |value|
          context "set to #{value}" do
            let(:params) { { :manage_firewall => value } }

            it { should contain_class('memcached') }

            it { should_not contain_firewall('100_tcp_11211_for_memcached') }
            it { should_not contain_firewall('100_udp_11211_for_memcached') }
          end
        end

        context 'set to an invalid type (array)' do
          let(:params) { { :manage_firewall => ['invalid','type'] } }

          it do
            expect {
              should contain_class('memcached')
            }.to raise_error(Puppet::Error)
          end
        end
      end
    end
  end

  let :default_params do
    {
      :package_ensure  => 'present',
      :logfile         => '/var/log/memcached.log',
      :max_memory      => false,
      :item_size       => false,
      :lock_memory     => false,
      :listen_ip       => '0.0.0.0',
      :tcp_port        => '11211',
      :udp_port        => '11211',
      :user            => 'nobody',
      :max_connections => '8192',
      :install_dev     => false,
      :processorcount  => 1,
      :use_sasl        => false,
      :large_mem_pages => false,
    }
  end

  [ {},
    {
      :package_ensure  => 'latest',
      :logfile         => '/var/log/memcached.log',
      :max_memory      => '2',
      :item_size       => false,
      :lock_memory     => true,
      :listen_ip       => '127.0.0.1',
      :tcp_port        => '11212',
      :udp_port        => '11213',
      :user            => 'somebdy',
      :max_connections => '8193',
      :verbosity       => 'vvv',
      :processorcount  => 3,
      :use_sasl        => true,
      :large_mem_pages => true,
    },
    {
      :package_ensure  => 'present',
      :logfile         => '/var/log/memcached.log',
      :max_memory      => '20%',
      :lock_memory     => false,
      :listen_ip       => '127.0.0.1',
      :tcp_port        => '11212',
      :udp_port        => '11213',
      :user            => 'somebdy',
      :max_connections => '8193',
      :verbosity       => 'vvv',
      :install_dev     => true,
      :processorcount  => 1
    },
    {
      :listen_ip       => '',
    },
    {
      :pidfile         => false,
    },
    {
      :pidfile         => '/var/log/memcached.pid',
    },
    {
      :package_ensure  => 'absent',
      :install_dev     => true
    },
    {
      :service_manage => false
    }
  ].each do |param_set|
    describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do

      let :param_hash do
        default_params.merge(param_set)
      end

      let :params do
        param_set
      end

      ['Debian'].each do |osfamily|

        let :facts do
          {
            :osfamily => osfamily,
            :memorysize => '1000 MB',
            :processorcount => '1',
          }
        end

        describe "on supported osfamily: #{osfamily}" do

          it { should contain_class("memcached::params") }

          it { should contain_package("memcached").with_ensure(param_hash[:package_ensure]) }

          it { should_not contain_firewall('100_tcp_11211_for_memcached') }
          it { should_not contain_firewall('100_udp_11211_for_memcached') }

          it {
            if param_hash[:install_dev]
            should contain_package("libmemcached-dev").with_ensure(param_hash[:package_ensure])
            end
          }

          it { should contain_file("/etc/memcached.conf").with(
            'owner'   => 'root',
            'group'   => 'root'
          )}

          it { 
            if param_hash[:service_manage] == false
              should_not contain_service('memcached')
            elsif param_hash[:package_ensure] == 'absent'
              should contain_service("memcached").with(
                'ensure'     => 'stopped',
                'enable'     => false
              )
            else
              should contain_service("memcached").with(
                'ensure'     => 'running',
                'enable'     => true,
                'hasrestart' => true,
                'hasstatus'  => false
              )
            end
          }

          it 'should compile the template based on the class parameters' do
            content = param_value(
              subject,
              'file',
              '/etc/memcached.conf',
              'content'
            )
            expected_lines = [
              "logfile #{param_hash[:logfile]}",
              "-p #{param_hash[:tcp_port]}",
              "-U #{param_hash[:udp_port]}",
              "-u #{param_hash[:user]}",
              "-c #{param_hash[:max_connections]}",
              "-t #{param_hash[:processorcount]}"
            ]
            if(param_hash[:max_memory])
              if(param_hash[:max_memory].end_with?('%'))
                expected_lines.push("-m 200")
              else
                expected_lines.push("-m #{param_hash[:max_memory]}")
              end
            else
              expected_lines.push("-m 950")
            end
            if(param_hash[:listen_ip] != '')
              expected_lines.push("-l #{param_hash[:listen_ip]}")
            end
            if(param_hash[:lock_memory])
              expected_lines.push("-k")
            end
            if(param_hash[:pidfile])
              expected_lines.push("-P #{param_hash[:pidfile]}")
            end
            if(param_hash[:verbosity])
              expected_lines.push("-vvv")
            end
            if(param_hash[:use_sasl])
              expected_lines.push("-S")
            end
            if(param_hash[:large_mem_pages])
              expected_lines.push("-L")
            end
            (content.split("\n") & expected_lines).should =~ expected_lines
          end
        end
      end
      ['Redhat'].each do |osfamily|
        describe 'on supported platform' do
          it 'should fail' do

          end
        end
      end
    end
  end
end

# vim: expandtab shiftwidth=2 softtabstop=2
