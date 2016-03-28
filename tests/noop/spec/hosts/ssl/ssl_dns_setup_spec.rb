# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'ssl/ssl_dns_setup.pp'

describe manifest do
  shared_examples 'catalog' do

    if Noop.hiera_structure('use_ssl', false)
      context "when all services have hostnames" do
        public_services = [ 'horizon', 'keystone', 'nova', 'heat', 'glance', 'cinder', 'neutron', 'swift', 'sahara', 'murano', 'ceilometer', 'radosgw']
        public_services.each do |service|
          public_vip = Noop.hiera_structure("use_ssl/#{service}_public_ip", Noop.hiera('public_vip'))
          public_hostname = Noop.hiera_structure "use_ssl/#{service}_public_hostname", Noop.hiera('management_vip')

          it "should set #{service} resolving for public hostanme" do
            should contain_host("#{public_hostname}").with(
              'ensure' => 'present',
              'ip'     => public_vip,
            )
          end
        end

        ia_services = [ 'keystone', 'nova', 'heat', 'glance', 'cinder', 'neutron', 'swift', 'sahara', 'murano', 'ceilometer' ]
        ia_services.each do |service|
          management_vip = Noop.hiera_structure("use_ssl/#{service}_internal_ip", Noop.hiera('management_vip'))
          admin_vip = Noop.hiera_structure("use_ssl/#{service}_admin_ip", Noop.hiera('management_vip'))
          internal_hostname = Noop.hiera_structure "use_ssl/#{service}_internal_hostname"
          admin_hostname = Noop.hiera_structure "use_ssl/#{service}_admin_hostname"

          it "should set #{service} resolving for internal hostname" do
            should contain_host("#{internal_hostname}").with(
              'ensure' => 'present',
              'ip'     => management_vip,
            )
          end

          it "should set #{service} resolution for admin hostname" do
            should contain_host("#{admin_hostname}").with(
              'ensure' => 'present',
              'ip'     => admin_vip,
            )
          end
        end
      end

      context "when keystone external ip set" do
        let(:public_ip) { Noop.hiera_structure "use_ssl/keystone_public_ip" }
        public_hostname = Noop.hiera_structure "use_ssl/keystone_public_hostname"
        let(:internal_ip) { Noop.hiera_structure "use_ssl/keystone_internal_ip" }
        internal_hostname = Noop.hiera_structure "use_ssl/keystone_internal_hostname"
        let(:admin_ip) { Noop.hiera_structure "use_ssl/keystone_admin_ip" }
        admin_hostname = Noop.hiera_structure "use_ssl/keystone_admin_hostname"

        it "should set resolve with keystone public external ip" do
          should contain_host("#{public_hostname}").with(
            'ensure' => 'present',
            'ip'     => public_ip,
          )
        end

        it "should set resolve with keystone internal external ip" do
          should contain_host("#{internal_hostname}").with(
            'ensure' => 'present',
            'ip'     => internal_ip,
          )
        end

        it "should set resolve with keystone admin external ip" do
          should contain_host("#{admin_hostname}").with(
            'ensure' => 'present',
            'ip'     => admin_ip,
          )
        end
      end
    elsif Noop.hiera_structure('public_ssl/services', false)
      it "should set resolving for public endpoints" do
        public_vip = Noop.hiera('public_vip')
        public_hostname = Noop.hiera_structure('public_ssl/hostname')

        should contain_host("#{public_hostname}").with(
          'ensure' => 'present',
          'ip'     => public_vip,
        )
      end
    end

  end
  test_ubuntu_and_centos manifest
end
