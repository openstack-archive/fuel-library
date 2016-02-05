require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-stats.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  shared_examples 'catalog' do

    management_vip = task.hiera 'management_vip'
    database_vip = task.hiera 'database_vip'
    database_vip ||= management_vip

    unless task.hiera('external_lb', false)
      it "should contain stats fragment and listen #{[management_vip, database_vip].uniq.inspect}" do
        [management_vip, database_vip].each do |ip|
          should contain_concat__fragment('stats_listen_block').with_content(
            %r{\n\s*bind\s+#{ip}:10000\s*$\n}
          )
        end
      end
    end

  end

  test_ubuntu_and_centos manifest
end
