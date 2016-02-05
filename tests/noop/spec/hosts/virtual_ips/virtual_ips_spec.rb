require 'spec_helper'
require 'shared-examples'
manifest = 'virtual_ips/virtual_ips.pp'

describe manifest do
  shared_examples 'catalog' do
    # TODO: test vip parameters too

    task.hiera_structure('network_metadata/vips', {}).each do |name, params|
      next unless params['network_role']
      next unless params['node_roles']

      it "should have '#{name}' VIP" do
        expect(subject).to contain_cluster__virtual_ip(name)
      end
    end
  end

  test_ubuntu_and_centos manifest
end
