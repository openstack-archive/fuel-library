# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'virtual_ips/conntrackd.pp'

describe manifest do
  shared_examples 'catalog' do

    it {
      if facts[:operatingsystem] == 'Ubuntu'
        if Noop.hiera_structure('network_metadata/vips/vrouter_pub/namespace', false)
          is_expected.to contain_class('Cluster::Conntrackd_ocf')
        else
          is_expected.to_not contain_class('Cluster::Conntrackd_ocf')
        end
      elsif facts[:operatingsystem] == 'CentOS'
        is_expected.to_not contain_class('Cluster::Conntrackd_ocf')
      end
    }

  end
  test_ubuntu_and_centos manifest
end

