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
manifest = 'generate_vms/generate_vms.pp'

describe manifest do
  shared_examples 'catalog' do
    libvirt_dir = '/etc/libvirt/qemu'
    template_dir = '/var/lib/nova'
    libvirt_service = 'libvirtd'
    packages = ['qemu-utils', 'qemu-kvm', 'libvirt-bin', 'xmlstarlet']

    vms = Noop.hiera 'vms_conf'

    it 'should exec generate_vms' do
      should contain_exec('generate_vms').with(
        'command'     => "/usr/bin/generate_vms.sh #{libvirt_dir} #{template_dir}",
      )
    end

    vms.each do | vm |
      it "should define osnailyfacter::generate_vms::vm_config #{vm}" do
        should contain_osnailyfacter__generate_vms__vm_config(vm).with(
          'before' => 'Exec[generate_vms]',
          'require' => "File[#{template_dir}]",
        )
      end
    end

    it "should create #{template_dir} directory" do
      should contain_file(template_dir).with(
        'ensure' => 'directory',
      )
    end

    it "should create #{libvirt_dir}/autostart directory" do
      should contain_file("#{libvirt_dir}/autostart").with(
        'ensure' => 'directory',
      )
    end

    it "should start #{libvirt_service} service" do
      should contain_service(libvirt_service).with(
        'ensure' => 'running',
        'before' => 'Exec[generate_vms]',
      )
    end

    packages.each do | package |
      it "should install #{package} package" do
        should contain_package(package).with(
          'ensure' => 'installed',
        )
      end
    end

    it 'should set permissions for /dev/kvm under Ubuntu' do
      if facts[:operatingsystem] == 'Ubuntu'
        should contain_file('/dev/kvm').with(
          :ensure => 'present',
          :group  => 'kvm',
          :mode   => '0660',
        ).that_comes_before('Exec[generate_vms]')
      end
    end

  end
  test_ubuntu_and_centos manifest
end
