# R_N: neut_gre.generate_vms ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'generate_vms/generate_vms.pp'

describe manifest do
  shared_examples 'catalog' do

    vms = Noop.hiera 'vms_conf'
    created = vms.collect{|x| x['created']}.compact.any?

    unless created
      libvirt_dir = '/etc/libvirt/qemu'
      template_dir = '/var/lib/nova'
      libvirt_service = 'libvirtd'
      packages = ['qemu-utils', 'qemu-kvm', 'libvirt-bin', 'xmlstarlet']

      vms.each do | vm |
        it "should define osnailyfacter::generate_vms::vm_config #{vm}" do
          should contain_osnailyfacter__generate_vms__vm_config(vm).with(
            'template_dir' => template_dir,
            'before'       => 'Exec[generate_vms]',
            'require'      => "File[#{template_dir}]",
          )
        end
      end

      it 'should exec generate_vms' do
        should contain_exec('generate_vms').with(
          'command'     => "/usr/bin/generate_vms.sh #{libvirt_dir} #{template_dir}",
        )
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
  end
  test_ubuntu_and_centos manifest
end
