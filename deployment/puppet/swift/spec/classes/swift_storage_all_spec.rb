require 'spec_helper'

describe 'swift::storage::all' do
  # TODO I am not testing the upstart code b/c it should be temporary

  let :facts do
    {
      :concat_basedir  => '/tmp/',
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :concat_basedir  => '/tmp/foo'
    }
  end

  let :pre_condition do
    "class { 'swift': swift_hash_suffix => 'changeme' }
     include ssh::server::install
    "
  end

  let :default_params do
    {
      :devices => '/srv/node',
      :object_port => '6000',
      :container_port => '6001',
      :account_port => '6002'
    }
  end

  describe 'when an internal network ip is not specified' do
    it 'should fail' do
      expect do
        subject
      end.should raise_error(Puppet::Error, /Must pass storage_local_net_ip/)
    end
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
        it { should contain_package("swift-#{type}").with_ensure('present') }
        it { should contain_service("swift-#{type}").with(
          {:provider  => 'upstart',
           :ensure    => 'running',
           :enable    => true,
           :hasstatus => true
          })}
        it { should contain_service("swift-#{type}-replicator").with(
          {:provider  => 'upstart',
           :ensure    => 'running',
           :enable    => true,
           :hasstatus => true
          }
        )}
        it { should contain_file("/etc/swift/#{type}-server/").with(
          {:ensure => 'directory',
           :owner  => 'swift',
           :group  => 'swift'}
        )}
      end

      let :storage_server_defaults do
        {:devices              => param_hash[:devices],
         :storage_local_net_ip => param_hash[:storage_local_net_ip]
        }
      end

      it { should contain_swift__storage__server(param_hash[:account_port]).with(
        {:type => 'account',
         :config_file_path => 'account-server.conf',
         :pipeline => param_hash[:account_pipeline] || 'account-server' }.merge(storage_server_defaults)
      )}
      it { should contain_swift__storage__server(param_hash[:object_port]).with(
        {:type => 'object',
         :config_file_path => 'object-server.conf',
         :pipeline => param_hash[:object_pipeline] || 'object-server' }.merge(storage_server_defaults)
      )}
      it { should contain_swift__storage__server(param_hash[:container_port]).with(
        {:type => 'container',
         :config_file_path => 'container-server.conf',
         :pipeline => param_hash[:container_pipeline] || 'container-server' }.merge(storage_server_defaults)
      )}

      it { should contain_class('rsync::server').with(
        {:use_xinetd => true,
         :address    => param_hash[:storage_local_net_ip]
        }
      )}

    end
  end

  describe "when installed on Debian" do
    let :facts do
      {
        :operatingsystem => 'Debian',
        :osfamily        => 'Debian',
        :concat_basedir  => '/tmp/foo'
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
          it { should contain_package("swift-#{type}").with_ensure('present') }
          it { should contain_service("swift-#{type}").with(
            {:provider  => nil,
              :ensure    => 'running',
              :enable    => true,
              :hasstatus => true
            })}
            it { should contain_service("swift-#{type}-replicator").with(
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
