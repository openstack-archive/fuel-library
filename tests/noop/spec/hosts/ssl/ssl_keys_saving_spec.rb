require 'spec_helper'
require 'shared-examples'
manifest = 'ssl/ssl_keys_saving.pp'

describe manifest do
  shared_examples 'catalog' do
    context 'for services that have all endpoint types' do
      services = [ 'keystone', 'nova', 'heat', 'glance', 'cinder', 'neutron', 'swift', 'sahara', 'murano', 'ceilometer' ]
      types = [ 'public', 'internal', 'admin' ]
      services.each do |service|
        types.each do |type|
          certdata = Noop.hiera_structure "use_ssl/#{service}_#{type}_certdata"
          it "should create certificate file with all data for #{type} #{service} in /etc/" do
            should contain_file("/etc/pki/tls/certs/#{service}_#{type}_haproxy.pem").with(
              'ensure'  => 'present',
              'content' => certdata,
            )
          end

          it "should create certificate file with all data for #{type} #{service} in /var/" do
            should contain_file("/var/lib/astute/haproxy/#{service}_#{type}.pem").with(
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
        certdata = Noop.hiera_structure "use_ssl/#{service}_public_certdata"
        it "should create certificate file with all data for public #{service} in /etc/" do
          should contain_file("/etc/pki/tls/certs/#{service}_public_haproxy.pem").with(
            'ensure'  => 'present',
            'content' => certdata,
          )
        end

        it "should create certificate file with all data for public #{service} in /var/" do
          should contain_file("/var/lib/astute/haproxy/#{service}_public.pem").with(
            'ensure'  => 'present',
            'content' => certdata,
          )
        end

        it "should not create certificate file for internal #{service} in /etc/" do
          should_not contain_file("/etc/pki/tls/certs/#{service}_internal_haproxy.pem")
        end

        it "should not create certificate file for internal #{service} in /var/" do
          should_not contain_file("/var/lib/astute/haproxy/#{service}_internal.pem")
        end

        it "should not create certificate file for admin #{service} in /etc/" do
          should_not contain_file("/etc/pki/tls/certs/#{service}_admin_haproxy.pem")
        end

        it "should not create certificate file for admin #{service} in /var/" do
          should_not contain_file("/var/lib/astute/haproxy/#{service}_admin.pem")
        end

      end
    end

  end
  test_ubuntu_and_centos manifest
end

