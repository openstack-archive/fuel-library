require 'spec_helper'
describe 'swift::storage::server' do

  let :pre_condition do
    "class { 'ssh::server::install': }
     class { 'swift': swift_hash_suffix => 'foo' }
     class { 'swift::storage': storage_local_net_ip => '10.0.0.1' }"
  end
  let :default_params do
    {:devices => '/srv/node',
     :owner => 'swift',
     :group  => 'swift',
     :max_connections => '25'}
  end



  describe 'with an invalid title' do
    let :params do
      {:storage_local_net_ip => '127.0.0.1',
      :type => 'object'}
    end
    let :title do
      'foo'
    end
    it 'should fail' do
      expect do
        subject
      end.should raise_error(Puppet::Error, /does not match/)
    end
  end

  ['account', 'object', 'container'].each do |t|
    [{:storage_local_net_ip => '10.0.0.1',
      :type => t},
     {:storage_local_net_ip => '127.0.0.1',
      :type => t}
    ].each do |param_set|
      describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
        let :title do
          '8000'
        end
        let :param_hash do
          default_params.merge(param_set)
        end
        let :params do
          param_set
        end
        let :config_file_path do
          "#{t}-server/#{title}.conf"
        end
        it { should contain_package("swift-#{t}").with_ensure('present') }
        it { should contain_service("swift-#{t}").with(
          :ensure    => 'running',
          :enable    => true,
          :hasstatus => true,
          :subscribe => 'Service[rsync]'
        )}
        it { should contain_file("/etc/swift/#{t}-server/").with(
          :ensure => 'directory',
          :owner  => 'swift',
          :group  => 'swift'
        )}
        it { should contain_rsync__server__module("#{t}#{title}").with(
          :path            => param_hash[:devices],
          :lock_file       => "/var/lock/#{t}#{title}.lock",
          :uid             => param_hash[:owner],
          :gid             => param_hash[:group],
          :max_connections => param_hash[:max_connections],
          :read_only       => false
        )}
        it { should contain_file("/etc/swift/#{config_file_path}").with(
          :owner => param_hash[:owner],
          :group => param_hash[:group]
        )}
        it 'should have some contents' do
          content = param_value(
            subject,
            'file', "/etc/swift/#{config_file_path}",
            'content'
          )
          expected_lines =
            [
              '[DEFAULT]',
              "devices = #{param_hash[:devices]}",
              "bind_ip = #{param_hash[:storage_local_net_ip]}",
              "bind_port = #{title}"
            ]
          (content.split("\n") & expected_lines).should =~ expected_lines
        end
      end

      # TODO - I do not want to add tests for the upstart stuff
      # I need to check the tickets and see if this stuff is fixed
    end
  end
end
