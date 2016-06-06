# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'vmware/vcenter.pp'

describe manifest do
  shared_examples 'catalog' do

    use_vcenter = Noop.hiera('use_vcenter', 'false')
    ssl_hash = Noop.hiera_hash 'use_ssl', {}
    vncproxy_protocol = 'https'
    vncproxy_port = '6080'
    vcnproxy_path = '/vnc_auto.html'

    if !ssl_hash.empty?
      vncproxy_host = Noop.hiera_structure('use_ssl/nova_public_hostname')
    elsif Noop.hiera_structure('public_ssl/services')
      vncproxy_host = Noop.hiera_structure('public_ssl/hostname')
    else
      vncproxy_host = Noop.hiera('public_vip')
      vncproxy_protocol = 'http'
    end

    if use_vcenter
      it 'should properly configure vncproxy with (non-)ssl' do
        should contain_class('vmware::controller').with(:vncproxy_host => vncproxy_host)
        should contain_class('vmware::controller').with(:vncproxy_protocol => vncproxy_protocol)
        should contain_class('vmware::controller').with(:vncproxy_port => vncproxy_port)
        should contain_class('vmware::controller').with(:vncproxy_path => vcnproxy_path)
      end
      it 'should configure novncproxy_base_url setting' do
        should contain_nova_config('vnc/novncproxy_base_url').with(
          :value => "#{vncproxy_protocol}://#{vncproxy_host}:#{vncproxy_port}#{vcnproxy_path}"
        )
      end
    end # end of use_vcenter
  end # end of shared_examples

  test_ubuntu_and_centos manifest
 end

