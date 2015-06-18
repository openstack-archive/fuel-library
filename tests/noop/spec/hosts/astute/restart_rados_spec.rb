require 'spec_helper'
require 'shared-examples'
manifest = 'astute/restart_rados.pp'

describe manifest do
  shared_examples 'catalog' do
    it "should contain restart of rados gateway" do
      case facts[:operatingsystem]
      when 'Ubuntu'
        service_name = 'radosgw'
      when 'CentOS'
        service_name = 'ceph-radosgw'
      end

      should contain_exec("restart-#{service_name}").with_command(
          "service #{service_name} restart")
    end

    it "should contain radowgw service" do
      case facts[:operatingsystem]
      when 'Ubuntu'
        service_name = 'radosgw'
      when 'CentOS'
        service_name = 'ceph-radosgw'
      end

      should contain_service(service_name)
    end
  end

  test_ubuntu_and_centos manifest
end
