# HIERA: neut_vxlan_dvr.murano.sahara-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl
# HIERA: neut_vxlan_dvr.murano.sahara-cinder.yaml
# HIERA: neut_vxlan_dvr.murano.sahara-compute.yaml

require 'spec_helper'
require 'shared-examples'
manifest = 'murano/rabbitmq.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:rabbit_user) { Noop.hiera_structure('rabbit/user', 'nova') }
    let(:rabbit_password) { Noop.hiera_structure('rabbit/password', 'secret') }
    let(:rabbit_vhost) { Noop.hiera_structure('murano/rabbit/vhost', '/') }

    let(:rabbit_node_name) { 'murano@localhost' }
    let(:rabbit_service_name) { 'murano-rabbitmq' }

    it { should contain_package('murano-rabbitmq').with(
      :ensure => 'present',
    )}

    it { should contain_service(rabbit_service_name).with(
      :ensure => 'running',
      :name   => rabbit_service_name,
      :enable => true
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
