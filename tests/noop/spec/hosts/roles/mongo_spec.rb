# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-cinder.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-mongo.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-ceph-osd.yaml ubuntu
# RUN: neut_vlan.ironic.controller.yaml ubuntu
# RUN: neut_vlan.ironic.conductor.yaml ubuntu
# RUN: neut_vlan.compute.ssl.yaml ubuntu
# RUN: neut_vlan.compute.ssl.overridden.yaml ubuntu
# RUN: neut_vlan.compute.nossl.yaml ubuntu
# RUN: neut_vlan.cinder-block-device.compute.yaml ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl.yaml ubuntu
# RUN: neut_gre.generate_vms.yaml ubuntu
require 'spec_helper'
require 'shared-examples'
manifest = 'roles/mongo.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :file
    MockFunction.new(:file) do |function|
      allow(function).to receive(:call).with(['/var/lib/astute/mongodb/mongodb.key']).and_return('1234567890')
    end
  end

  shared_examples 'catalog' do
    debug = Noop.hiera 'debug'
    use_syslog = Noop.hiera 'use_syslog'
    ceilometer_hash = Noop.hiera_structure 'ceilometer'
    mongodb_port = Noop.hiera('mongodb_port', '27017')
    oplog_size = Noop.hiera('mongo/oplog_size', '10240')
    profile = Noop.hiera('mongo/profile', '1')
    directoryperdb = Noop.hiera('mongo/directoryperdb', true)
    keyfile = '/etc/mongodb.key'

    it 'should configure MongoDB only with replica set' do
      should contain_class('mongodb::server').with('replset' => 'ceilometer')
    end

    it 'should configure MongoDB with authentication enabled' do
      should contain_class('mongodb::server').with('auth' => 'true')
      should contain_class('mongodb::server').with('create_admin' => 'true')
      should contain_class('mongodb::server').with('store_creds' => 'true')
      should contain_file("#{facts[:root_home]}/.mongorc.js").with('ensure' => 'present')
    end

    it 'should configure verbosity level for MongoDB' do
      if debug
        should contain_class('mongodb::server').with('verbositylevel' => 'vv')
      else
        should contain_class('mongodb::server').with('verbositylevel' => 'v')
      end
    end

    it 'should use keyfile for replica setup' do
      should contain_file(keyfile).with('mode' => '0600', 'owner' => 'mongodb', 'content' => '1234567890')
      should contain_class('mongodb::server').with('keyfile' => keyfile)
    end

    it 'should not write logs to file if syslog is enabled' do
      if use_syslog
        should contain_class('mongodb::server').with('logpath' => 'false')
      end
    end

    it 'should configure oplog size for local database' do
      should contain_class('mongodb::server').with('oplog_size' => oplog_size)
    end

    it 'should capture data regarding performance' do
      should contain_class('mongodb::server').with('profile' => profile)
   end

    it 'should store each database in separate directory' do
      should contain_class('mongodb::server').with('directoryperdb' => directoryperdb)
    end

  end

  test_ubuntu_and_centos manifest
end

