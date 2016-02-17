require 'spec_helper'
require 'shared-examples'
manifest = 'master/cobbler-only.pp'

describe manifest do
  shared_examples 'catalog' do
    [
      'centos-x86_64',
      'ubuntu_1404_x86_64',
      'bootstrap',
      'ubuntu_bootstrap'
    ].each do |profile|
      it {
        should contain_cobbler_profile(profile).with_kopts(
          /.*\bamd_iommu=on\b.*\bintel_iommu=on\b.*/
        )
      }
    end
  end # catalog
  test_centos manifest
end
