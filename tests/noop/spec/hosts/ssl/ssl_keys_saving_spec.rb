# ROLE: virt
# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: controller
# ROLE: compute-vmware
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder
# ROLE: ceph-osd
require 'spec_helper'
require 'shared-examples'
manifest = 'ssl/ssl_keys_saving.pp'


describe manifest do
  shared_examples 'catalog' do
    if Noop.hiera('use_ssl', false)
      context 'for services that have all endpoint types' do
        services = [ 'keystone', 'nova', 'heat', 'glance', 'cinder', 'neutron', 'swift', 'sahara', 'murano', 'ceilometer' ]
        types = [ 'public', 'internal', 'admin' ]
        services.each do |service|
          types.each do |type|
            certdata = Noop.hiera_structure "use_ssl/#{service}_#{type}_certdata/content"
            it "should create certificate file with all data for #{type} #{service} in /etc/" do
              should contain_file("/etc/pki/tls/certs/#{type}_#{service}.pem").with(
                'ensure'  => 'present',
                'content' => certdata,
              )
            end

            it "should create certificate file with all data for #{type} #{service} in /var/" do
              should contain_file("/var/lib/astute/haproxy/#{type}_#{service}.pem").with(
                'ensure'  => 'present',
                'content' => certdata,
              )
            end
          end
        end
      end

      context 'for public-only services' do
        services = [ 'horizon', 'radosgw' ]
        services.each do |service|
          certdata = Noop.hiera_structure "use_ssl/#{service}_public_certdata/content"
          it "should create certificate file with all data for public #{service} in /etc/" do
            should contain_file("/etc/pki/tls/certs/public_#{service}.pem").with(
              'ensure'  => 'present',
              'content' => certdata,
            )
          end

          it "should create certificate file with all data for public #{service} in /var/" do
            should contain_file("/var/lib/astute/haproxy/public_#{service}.pem").with(
              'ensure'  => 'present',
              'content' => certdata,
            )
          end

          it "should not create certificate file for internal #{service} in /etc/" do
            should_not contain_file("/etc/pki/tls/certs/internal_#{service}.pem")
          end

          it "should not create certificate file for internal #{service} in /var/" do
            should_not contain_file("/var/lib/astute/haproxy/internal_#{service}.pem")
          end

          it "should not create certificate file for admin #{service} in /etc/" do
            should_not contain_file("/etc/pki/tls/certs/admin_#{service}.pem")
          end

          it "should not create certificate file for admin #{service} in /var/" do
            should_not contain_file("/var/lib/astute/haproxy/admin_#{service}.pem")
          end

        end
      end

    elsif Noop.hiera_hash('public_ssl', false)
      certdata = Noop.hiera_structure "public_ssl/cert_data/content"
      it "should create certificate file for public endpoints in /var/" do
        should contain_file("/var/lib/astute/haproxy/public_haproxy.pem").with(
          'ensure'  => 'present',
          'content' => certdata.to_s,
        )
      end
      it "should create certificate file with for public endpoints in /etc/" do
        should contain_file("/etc/pki/tls/certs/public_haproxy.pem").with(
          'ensure'  => 'present',
          'content' => certdata.to_s,
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

