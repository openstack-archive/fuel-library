require 'spec_helper'
require 'shared-examples'
manifest = 'astute/dump_rabbitmq_definitions.pp'

describe manifest do
  shared_examples 'catalog' do
    rabbit_hash = Noop.hiera_structure 'rabbit_hash'
    original_definitions_dump_file = '/etc/rabbitmq/definitions.full'
    rabbit_api_endpoint = 'http://localhost:15672/api/definitions'

    it "should contain rabbitmq dump definitions exec" do

      should contain_dump_rabbitmq_definitions(original_definitions_dump_file).with(
          :user      => rabbit_hash['user'],
          :password  => rabbit_hash['password'],
          :url       => rabbit_api_endpoint,
      )
      should contain_exec('rabbitmq-dump-clean').with(
          :refresh_only => true,
      )
      ['/etc/rabbitmq/definitions', '/etc/rabbitmq/definitions.full'].each do |f|
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
