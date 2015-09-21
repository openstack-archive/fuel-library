require 'spec_helper'
require 'shared-examples'
manifest = 'astute/enable_edac.pp'


describe manifest do
  shared_examples 'catalog' do
    it "should enable edac" do
      it { should contain_kmod__load('edac_core') }
      check_pci_errors_file = '/sys/devices/system/edac/pci/check_pci_errors'
      is_expected.to contain_exec('enable_check_pci_errors').with(
        :path    => '/usr/bin:/usr/sbin:/sbin:/bin',
        :command => "echo "1" > '/sys/devices/system/edac/pci/check_pci_errors'",
        :only_if => "test -e '/sys/devices/system/edac/pci/check_pci_errors'"
      )
    end
  end
  test_ubuntu_and_centos manifest
end
