# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/enable_rados.pp'

describe manifest do
  shared_examples 'catalog' do
    it "should contain radosgw service" do

      if facts[:operatingsystem] == 'Ubuntu'
        should contain_service('radosgw').with(
          :enable   => 'false',
          :provider => 'debian'
        )

        should contain_service('radosgw-all').with(
          :ensure   => 'running',
          :enable   => 'true',
          :provider => 'upstart'
        )
      else
        should contain_service('ceph-radosgw').with(
          :ensure => 'running',
          :enable => 'true'
        )
      end
    end

    it "should create radosgw init override file on Ubuntu" do
        if facts[:operatingsystem] == 'Ubuntu'
          should contain_file("/etc/init/radosgw-all.override").with(
            :ensure  => 'present',
            :mode    => '0644',
            :owner   => 'root',
            :group   => 'root',
            :content => "start on runlevel [2345]\nstop on starting rc RUNLEVEL=[016]\n"

          )
        end
    end

    it "should wait until radosgw get ready" do
        ssl_hash = Noop.hiera_hash('use_ssl', {})
        service_endpoint = Noop.hiera('service_endpoint', '')
        management_vip = Noop.hiera('management_vip', '')
        rgw_protocol = Noop.puppet_function 'get_ssl_property', ssl_hash, {}, 'radosgw', 'internal', 'protocol', 'http'
        rgw_address = Noop.puppet_function 'get_ssl_property', ssl_hash, {}, 'radosgw', 'internal', 'hostname', [service_endpoint, management_vip]
        rgw_url = "#{rgw_protocol}://#{rgw_address}:8080/info"

        should contain_haproxy_backend_status('object-storage').with(
          :url      => rgw_url,
          :provider => 'http'
        )
    end
  end

  test_ubuntu_and_centos manifest
end
