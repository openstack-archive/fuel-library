# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'astute/purge_service_entries.pp'

describe manifest do
  shared_examples 'catalog' do

    deleted_nodes = Noop.hiera('deleted_nodes', [])

    unless deleted_nodes.empty?
      it 'should purge deleted nodes' do
        deleted_nodes.each do |deleted|
          is_expected.to contain_nova_service(deleted).with_ensure('absent')
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end
