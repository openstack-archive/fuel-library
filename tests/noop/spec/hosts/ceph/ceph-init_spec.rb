require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/init.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera 'storage'

    if (storage_hash['images_ceph'] or storage_hash['objects_ceph'] or storage_hash['objects_ceph'])
      it "should contain ceph service" do
        case facts[:operatingsystem]
        when 'Ubuntu'
          service_name = 'ceph-all'
        when 'CentOS'
          service_name = 'ceph'
        end
  
        should contain_service(service_name).with(
          'ensure' => 'running',
          'enable' => 'true'
        )
  
        if (facts[:operatingsystem] == 'Ubuntu')
          should contain_service(service_name).with_name('ceph-all')
        end
      end
    end
  end

  test_ubuntu_and_centos manifest
end

