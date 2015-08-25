require 'spec_helper'
require 'shared-examples'
manifest = 'generate_vms/generate_vms.pp'

describe manifest do
  shared_examples 'catalog' do
    libvirt_dir = '/etc/libvirt/qemu'
    template_dir = '/var/lib/vms'
    libvirt_service = 'libvirtd'
    packages = ['qemu-utils', 'qemu-kvm', 'libvirt-bin', 'xmlstarlet']

    vms = Noop.hiera 'vms_conf'

    it 'should exec generate_vms' do
      should contain_exec('generate_vms').with(
        'command'     => "/usr/bin/generate_vms.sh #{libvirt_dir} #{template_dir}",
        'notify'      => "Service[#{libvirt_service}]",
      )
    end

    vms.each do | vm |
      it "should define vm_config #{vm}" do
        should contain_vm_config(vm).with(
          'before' => 'Exec[generate_vms]',
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
      )
    end

    packages.each do | package |
      it "should install #{package} package" do
        should contain_package(package).with(
          'ensure' => 'installed',
        )
      end
    end

  end
  test_ubuntu_and_centos manifest
end
