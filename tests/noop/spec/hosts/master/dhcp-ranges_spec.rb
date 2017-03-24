require 'spec_helper'
require 'shared-examples'
manifest = 'master/dhcp-ranges.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    context 'with empty admin_networks' do
      it 'should not create any dhcp ranges' do
        is_expected.to have_nailgun__dnsmasq__dhcp_range_resource_count 0
      end
    end
  end
  run_test manifest
end
