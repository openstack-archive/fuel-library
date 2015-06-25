require 'spec_helper'
require 'shared-examples'
manifest = 'astute/enable_rados.pp'

describe manifest do
  shared_examples 'catalog' do
    it "should contain radowgw service" do
      case facts[:operatingsystem]
      when 'Ubuntu'
        service_name = 'radosgw'
      when 'CentOS'
        service_name = 'ceph-radosgw'
      end

      should contain_service(service_name).with(
        'ensure' => 'running',
        'enable' => 'true'
      )

      if (facts[:operatingsystem] == 'Ubuntu')
        should contain_service(service_name).with_provider('debian')
      end
    end
  end

  test_ubuntu_and_centos manifest
end
