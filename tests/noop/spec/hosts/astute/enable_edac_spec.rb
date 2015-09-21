require 'spec_helper'
require 'shared-examples'
manifest = 'astute/enable_edac.pp'


describe manifest do
  shared_examples 'catalog' do
    it "should enable edac" do
      should contain_kmod__load('edac_core')

      ["check_pci_errors", "edac_mc_log_ce", "edac_mc_log_ue"].each do |option|
        should contain_kmod__option("option ${title}").with(
          :option => $option,
          :value => '1',
          :module => 'edac_core'
        )

        config_file = /sys/devices/system/edac/pci/${option}
        is_expected.to contain_exec("update ${option}").with(
          :path    => '/usr/bin:/usr/sbin:/sbin:/bin',
          :command => "echo -n '1' > '${config_file}'",
          :onlyif  => "test -w '${config_file}' && test '${value}' != `cat '${config_file}'`"
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
