require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-stats.pp'

describe manifest do
  shared_examples 'catalog' do
    management_vip = Noop.hiera 'management_vip'

    it "should contain stats fragment and listen only #{management_vip}" do
      should contain_concat__fragment('stats_listen_block').with_content(
        %r{\n\s*bind\s+#{management_vip}:10000\s*$\n}
      )
    end
  end
  test_ubuntu_and_centos manifest
end
