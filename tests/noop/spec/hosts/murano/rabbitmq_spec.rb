require 'spec_helper'
require 'shared-examples'
manifest = 'murano/rabbitmq.pp'

describe manifest do
  shared_examples 'rabbitmq' do

    let(:rabbit_user) { Noop.hiera_structure('rabbit/user', 'murano') }
    let(:rabbit_password) { Noop.hiera_structure('rabbit/password', 'secret') }
    let(:rabbit_vhost) { '/' }

    let(:rabbit_port) { '55572' }
    let(:rabbit_cluster_port) { '41056' }
    let(:rabbit_node_name) { 'murano@localhost' }
    let(:rabbit_service_name) { 'rabbitmq-server-murano' }
    let(:rabbit_firewall_rule) { '203 murano-rabbitmq' }

    if :osfamily == "RedHat"
      let(:init_script_file) { 'murano-rabbitmq-init-centos.erb' }
      let(:init_install_cmd) { "chkconfig --add '/etc/init.d/#{rabbit_service_name}'" }
    elsif :osfamily == "Debian"
      let(:init_script_file) { 'murano-rabbitmq-init-ubuntu.erb' }
      let(:init_install_cmd) { "update-rc.d '#{rabbit_service_name}' defaults" }
    end

    it { should contain_file('rabbitmq_config').with(
      :path  => '/etc/rabbitmq/rabbitmq-murano.config',
      :owner => 'root',
      :group => 'root',
      :mode  => '0644'
    )}

    it { should contain_file('rabbitmq_config').with_content(/\{rabbit, \[\{tcp_listeners, \[#{rabbit_port}\]\}\]\}/) }
    it { should contain_file('rabbitmq_config').with_content(/\{inet_dist_listen_min, #{rabbit_cluster_port}\}/) }
    it { should contain_file('rabbitmq_config').with_content(/\{inet_dist_listen_max, #{rabbit_cluster_port}\}/) }

    it { should contain_file('init_script').with(
      :path  => "/etc/init.d/#{rabbit_service_name}",
      :owner => 'root',
      :group => 'root',
      :mode  => '0755'
    )}

    it { should contain_file('init_script').with_content(/export RABBITMQ_NODE_PORT=\"#{rabbit_port}\"/) }

    it { should contain_exec('install_init_script').with(
      :command => init_install_cmd,
      :unless  => "test -f /etc/init.d/#{rabbit_service_name}"
    )}

    it { should contain_service(rabbit_service_name).with(
      :ensure => 'running',
      :name   => rabbit_service_name,
      :enable => true
    )}

    it { should contain_firewall(rabbit_firewall_rule).with(
      :dport  => [ rabbit_port ],
      :proto  => 'tcp',
      :action => 'accept'
    )}

    it { should contain_exec('remove_murano_guest').with(
      :command => "rabbitmqctl -n '#{rabbit_node_name}' delete_user guest",
      :onlyif  => "rabbitmqctl -n '#{rabbit_node_name}' list_users | grep -qE '^guest\\s*\\['"
    )}

    it { should contain_exec('create_murano_user').with(
      :command => "rabbitmqctl -n '#{rabbit_node_name}' add_user '#{rabbit_user}' '#{rabbit_password}'",
      :unless  => "rabbitmqctl -n '#{rabbit_node_name}' list_users | grep -qE '^#{rabbit_user}\\s*\\['"
    )}

    it { should contain_exec('create_murano_vhost').with(
      :command => "rabbitmqctl -n '#{rabbit_node_name}' add_vhost '#{rabbit_vhost}'",
      :unless  => "rabbitmqctl -n '#{rabbit_node_name}' list_vhosts | grep -qE '^#{rabbit_vhost}$'"
    )}

    it { should contain_exec('set_murano_user_permissions').with(
      :command => "rabbitmqctl -n '#{rabbit_node_name}' set_permissions -p '#{rabbit_vhost}' '#{rabbit_user}' '.*' '.*' '.*'"
    )}
  end

  test_ubuntu_and_centos manifest
end
