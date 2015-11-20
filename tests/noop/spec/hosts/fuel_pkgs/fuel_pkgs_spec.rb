require 'spec_helper'
require 'shared-examples'
manifest = 'fuel_pkgs/fuel_pkgs.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should have ruby deep_merge installed' do
      case facts[:operatingsystem]
      when 'Ubuntu'
        package_name = 'ruby-deep-merge'
      when 'CentOS'
        package_name = 'rubygem-deep_merge'
      end

      should contain_package('rubygem-deep_merge').with(
        'ensure' => 'present',
        'name'   => package_name
      )
    end
  end

  test_ubuntu_and_centos manifest
end

