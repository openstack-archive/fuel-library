# RUN: neut_tun.ceph.murano.sahara.ceil-mongo ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-cinder ubuntu
# RUN: neut_tun.ironic-ironic ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-ceph-osd ubuntu
# RUN: neut_vlan.ceph-ceph-osd ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ironic-primary-controller ubuntu
# RUN: neut_tun.l3ha-primary-controller ubuntu
# RUN: neut_vlan.ceph-primary-controller ubuntu
# RUN: neut_vlan.dvr-primary-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-compute ubuntu
# RUN: neut_vlan.ceph-compute ubuntu
# RUN: neut_vlan.murano.sahara.ceil-compute ubuntu
# R_N: neut_gre.generate_vms ubuntu
require 'spec_helper'
require 'shared-examples'
manifest = 'fuel_pkgs/setup_repositories.pp'

describe manifest do
  shared_examples 'catalog' do

    if Noop.hiera_structure('repo_data/repo_type', false)
      repo_type    = Noop.hiera_structure('repo_data/repo_type')
      uca_repo_url = Noop.hiera_structure('repo_data/uca_repo_url')
      os_release   = Noop.hiera_structure('repo_data/uca_openstack_release')
      pin_haproxy  = Noop.hiera_structure('repo_data/pin_haproxy')
      pin_rabbitmq = Noop.hiera_structure('repo_data/pin_rabbitmq')
      pin_ceph  = Noop.hiera_structure('repo_data/pin_ceph')
    else
      repo_type = 'fuel'
    end

    before(:each) do
      Noop.puppet_function_load :generate_apt_pins
      MockFunction.new(:generate_apt_pins) do |function|
        allow(function).to receive(:call).and_return({})
      end
    end

    it 'apt-get should allow unathenticated packages' do
      should contain_apt__conf('allow-unathenticated').with_content('APT::Get::AllowUnauthenticated 1;')
    end

    it 'apt-get shouldn\'t install recommended packages' do
      should contain_apt__conf('install-recommends').with_content('APT::Install-Recommends "false";')
    end

    it 'apt-get shouldn\'t install suggested packages' do
      should contain_apt__conf('install-suggests').with_content('APT::Install-Suggests "false";')
    end

    if repo_type != 'fuel'
      it 'uca package pins should be configured' do
         should contain_apt__pin('haproxy-mos')
         should contain_apt__pin('ceph-mos')
         should contain_apt__pin('rabbitmq-server-mos')
         should contain_apt__pin('openvswitch-mos')
      end
   end
  end
  test_ubuntu manifest
end
