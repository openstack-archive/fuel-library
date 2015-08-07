require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/init.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera 'storage'

    it "should contain ceph service" do
      case facts[:operatingsystem]
      when 'Ubuntu'
        service_name = 'ceph-all'
      when 'CentOS'
        service_name = 'ceph'
      end

      if (storage_hash['images_ceph'] or storage_hash['objects_ceph'] or storage_hash['objects_ceph'])

        should contain_service('ceph').with(
          'name'   => service_name,
          'ensure' => 'running',
          'enable' => 'true'
        )

        if (facts[:operatingsystem] == 'Ubuntu')
          should contain_service('ceph').with_name(service_name)
        elsif (facts[:operatingsystem] == 'CentOS')
          should contain_service('ceph').with_name(service_name)
        end
      else
        should_not contain_service('ceph')
      end
    end
  end

  test_ubuntu_and_centos manifest
end

