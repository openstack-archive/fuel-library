require 'spec_helper'
describe 'swift::storage::server' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :processorcount  => 1
    }

  end

  let :pre_condition do
    "class { 'swift': swift_hash_suffix => 'foo' }
     class { 'swift::storage': storage_local_net_ip => '10.0.0.1' }"
  end
  let :default_params do
    {
      :devices         => '/srv/node',
      :owner           => 'swift',
      :group           => 'swift',
      :incoming_chmod  => '0644',
      :outgoing_chmod  => '0644',
      :max_connections => '25'
    }
  end

  describe 'with an invalid title' do
    let :params do
      {:storage_local_net_ip => '127.0.0.1',
      :type => 'object'}
    end
    let :title do
      'foo'
    end
    it_raises 'a Puppet::Error', /does not match/
  end

  ['account', 'object', 'container'].each do |t|

    describe "for type #{t}" do

      let :title do
        '8000'
      end

      let :req_params do
        {:storage_local_net_ip => '10.0.0.1', :type => t}
      end
      let :params do
        req_params
      end

      it { is_expected.to contain_package("swift-#{t}").with_ensure('present') }
      it { is_expected.to contain_service("swift-#{t}").with(
        :ensure    => 'running',
        :enable    => true,
        :hasstatus => true
      )}
      let :fragment_file do
        "/var/lib/puppet/concat/_etc_swift_#{t}-server_#{title}.conf/fragments/00_swift-#{t}-#{title}"
      end

      describe 'when parameters are overridden' do
        {
          :devices     => '/tmp/foo',
          :user        => 'dan',
          :mount_check => true,
          :workers     => 7,
          :pipeline    => ['foo'],
        }.each do |k,v|
          describe "when #{k} is set" do
            let :params do req_params.merge({k => v}) end
            it { is_expected.to contain_file(fragment_file) \
              .with_content(
                /^#{k.to_s}\s*=\s*#{v.is_a?(Array) ? v.join(' ') : v}\s*$/
              )
            }
          end
        end
        describe "when pipeline is passed an array" do
          let :params do req_params.merge({:pipeline => ['healthcheck','recon','test']})  end
          it { is_expected.to contain_concat__fragment("swift-#{t}-#{title}").with(
            :content => /^pipeline\s*=\s*healthcheck recon test\s*$/,
            :before => ["Swift::Storage::Filter::Healthcheck[#{t}]", "Swift::Storage::Filter::Recon[#{t}]", "Swift::Storage::Filter::Test[#{t}]"]
          )}
        end
        describe "when pipeline is not passed an array" do
          let :params do req_params.merge({:pipeline => 'not an array'}) end
          it_raises 'a Puppet::Error', /is not an Array/
        end

        describe "when replicator_concurrency is set" do
          let :params do req_params.merge({:replicator_concurrency => 42}) end
          it { is_expected.to contain_file(fragment_file) \
            .with_content(/\[#{t}-replicator\]\nconcurrency\s*=\s*42\s*$/m)
          }
        end
        if t != 'account'
          describe "when updater_concurrency is set" do
            let :params do req_params.merge({:updater_concurrency => 73}) end
            it { is_expected.to contain_file(fragment_file) \
              .with_content(/\[#{t}-updater\]\nconcurrency\s*=\s*73\s*$/m)
            }
          end
        else
          describe "when reaper_concurrency is set" do
            let :params do req_params.merge({:reaper_concurrency => 4682}) end
            it { is_expected.to contain_file(fragment_file) \
              .with_content(/\[#{t}-reaper\]\nconcurrency\s*=\s*4682\s*$/m)
            }
          end
        end
        if t == 'container'
          describe "when allow_versioning is set" do
           let :params do req_params.merge({ :allow_versions => false, }) end
            it { is_expected.to contain_file(fragment_file).with_content(/\[app:container-server\]\nallow_versions\s*=\s*false\s*$/m)}
          end
        end
        describe "when log_udp_port is set" do
          context 'and log_udp_host is not set' do
            let :params do req_params.merge({ :log_udp_port => 514}) end
             it_raises 'a Puppet::Error', /log_udp_port requires log_udp_host to be set/
            end
          context 'and log_udp_host is set' do
            let :params do req_params.merge(
              { :log_udp_host => '127.0.0.1',
                :log_udp_port => '514'})
            end
            it { is_expected.to contain_file(fragment_file).with_content(/^log_udp_host\s*=\s*127\.0\.0\.1\s*$/) }
            it { is_expected.to contain_file(fragment_file).with_content(/^log_udp_port\s*=\s*514\s*$/) }
          end
        end
      end

      describe 'with all allowed defaults' do
        let :params do
          req_params
        end

        it { is_expected.to contain_rsync__server__module("#{t}").with(
          :path            => '/srv/node',
          :lock_file       => "/var/lock/#{t}.lock",
          :uid             => 'swift',
          :gid             => 'swift',
          :incoming_chmod  => '0644',
          :outgoing_chmod  => '0644',
          :max_connections => 25,
          :read_only       => false
        )}

        # verify template lines
        it { is_expected.to contain_file(fragment_file).with_content(/^devices\s*=\s*\/srv\/node\s*$/) }
        it { is_expected.to contain_file(fragment_file).with_content(/^bind_ip\s*=\s*10\.0\.0\.1\s*$/) }
        it { is_expected.to contain_file(fragment_file).with_content(/^bind_port\s*=\s*#{title}\s*$/) }
        it { is_expected.to contain_file(fragment_file).with_content(/^mount_check\s*=\s*false\s*$/) }
        it { is_expected.to contain_file(fragment_file).with_content(/^user\s*=\s*swift\s*$/) }
        it { is_expected.to contain_file(fragment_file).with_content(/^set log_name\s*=\s*#{t}-server\s*$/) }
        it { is_expected.to contain_file(fragment_file).with_content(/^set log_facility\s*=\s*LOG_LOCAL2\s*$/) }
        it { is_expected.to contain_file(fragment_file).with_content(/^set log_level\s*=\s*INFO\s*$/) }
        it { is_expected.to contain_file(fragment_file).with_content(/^set log_address\s*=\s*\/dev\/log\s*$/) }
        it { is_expected.to contain_file(fragment_file).with_content(/^workers\s*=\s*1\s*$/) }
        it { is_expected.to contain_file(fragment_file).with_content(/^concurrency\s*=\s*1\s*$/) }
        it { is_expected.to contain_file(fragment_file).with_content(/^pipeline\s*=\s*#{t}-server\s*$/) }
      end
    end
  end
end
