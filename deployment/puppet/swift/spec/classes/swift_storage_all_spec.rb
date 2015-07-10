require 'spec_helper'

describe 'swift::storage::all' do
  # TODO I am not testing the upstart code b/c it should be temporary

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian'
    }
  end

  let :pre_condition do
    "class { 'swift': swift_hash_suffix => 'changeme' }"
  end

  let :default_params do
    {
      :devices => '/srv/node',
      :object_port => '6000',
      :container_port => '6001',
      :account_port => '6002',
      :log_facility => 'LOG_LOCAL2'
    }
  end

  describe 'when an internal network ip is not specified' do
    it_raises 'a Puppet::Error', /Must pass storage_local_net_ip/
  end

  [{  :storage_local_net_ip => '127.0.0.1' },
   {
      :devices => '/tmp/node',
      :storage_local_net_ip => '10.0.0.1',
      :object_port => '7000',
      :container_port => '7001',
      :account_port => '7002',
      :object_pipeline => ["1", "2"],
      :container_pipeline => ["3", "4"],
      :account_pipeline => ["5", "6"],
      :allow_versions => true,
      :log_facility => ['LOG_LOCAL2', 'LOG_LOCAL3'],
    }
  ].each do |param_set|

    describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
      let :param_hash do
        default_params.merge(param_set)
      end

      let :params do
        param_set
      end

      ['object', 'container', 'account'].each do |type|
        it { is_expected.to contain_package("swift-#{type}").with_ensure('present') }
        it { is_expected.to contain_service("swift-#{type}").with(
          {:provider  => 'upstart',
           :ensure    => 'running',
           :enable    => true,
           :hasstatus => true
          })}
        it { is_expected.to contain_service("swift-#{type}-replicator").with(
          {:provider  => 'upstart',
           :ensure    => 'running',
           :enable    => true,
           :hasstatus => true
          }
        )}
        it { is_expected.to contain_file("/etc/swift/#{type}-server/").with(
          {:ensure => 'directory',
           :owner  => 'swift',
           :group  => 'swift'}
        )}
      end

      let :storage_server_defaults do
        {:devices              => param_hash[:devices],
         :storage_local_net_ip => param_hash[:storage_local_net_ip],
         :log_facility         => param_hash[:log_facility]
        }
      end

      it { is_expected.to contain_swift__storage__server(param_hash[:account_port]).with(
        {:type => 'account',
         :config_file_path => 'account-server.conf',
         :pipeline => param_hash[:account_pipeline] || ['account-server'] }.merge(storage_server_defaults)
      )}
      it { is_expected.to contain_swift__storage__server(param_hash[:object_port]).with(
        {:type => 'object',
         :config_file_path => 'object-server.conf',
         :pipeline => param_hash[:object_pipeline] || ['object-server'] }.merge(storage_server_defaults)
      )}
      it { is_expected.to contain_swift__storage__server(param_hash[:container_port]).with(
        {:type => 'container',
         :config_file_path => 'container-server.conf',
         :pipeline => param_hash[:container_pipeline] || ['container-server'],
         :allow_versions => param_hash[:allow_versions] || false }.merge(storage_server_defaults)
      )}

      it { is_expected.to contain_class('rsync::server').with(
        {:use_xinetd => true,
         :address    => param_hash[:storage_local_net_ip],
         :use_chroot => 'no'
        }
      )}

    end
  end

  describe "when installed on Debian" do
    let :facts do
      {
        :operatingsystem => 'Debian',
        :osfamily        => 'Debian'
      }
    end

    [{  :storage_local_net_ip => '127.0.0.1' },
      {
      :devices => '/tmp/node',
      :storage_local_net_ip => '10.0.0.1',
      :object_port => '7000',
      :container_port => '7001',
      :account_port => '7002'
    }
    ].each do |param_set|
      describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
        let :param_hash do
          default_params.merge(param_set)
        end

        let :params do
          param_set
        end
        ['object', 'container', 'account'].each do |type|
          it { is_expected.to contain_package("swift-#{type}").with_ensure('present') }
          it { is_expected.to contain_service("swift-#{type}").with(
            {:provider  => nil,
              :ensure    => 'running',
              :enable    => true,
              :hasstatus => true
            })}
            it { is_expected.to contain_service("swift-#{type}-replicator").with(
              {:provider  => nil,
                :ensure    => 'running',
                :enable    => true,
                :hasstatus => true
              }
            )}
        end
      end
    end
  end
end
