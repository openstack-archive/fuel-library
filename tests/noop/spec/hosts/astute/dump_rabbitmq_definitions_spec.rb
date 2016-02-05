require 'spec_helper'
require 'shared-examples'
manifest = 'astute/dump_rabbitmq_definitions.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  shared_examples 'catalog' do
    it "should contain rabbitmq dump definitions exec" do
      should contain_exec('rabbitmq-dump-definitions')
      should contain_exec('rabbitmq-dump-clean')
      %w(/etc/rabbitmq/definitions /etc/rabbitmq/definitions.full).each do |f|
        should contain_file(f).with(
          :ensure => 'file',
          :owner  => 'root',
          :group  => 'root',
          :mode   => '0600')
      end
    end
  end
  test_ubuntu_and_centos manifest
end
