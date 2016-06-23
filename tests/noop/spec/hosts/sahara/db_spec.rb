# ROLE: primary-controller

require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/db.pp'

describe manifest do
  shared_examples 'catalog' do
    sahara_enabled = Noop.hiera_structure('sahara/enabled', false)

    it 'should install proper mysql-client', :if => sahara_enabled do
      if facts[:osfamily] == 'RedHat'
        pkg_name = 'MySQL-client-wsrep'
      elsif facts[:osfamily] == 'Debian'
        pkg_name = facts[:operatingsystemmajrelease] ? {
          '14'    => 'mysql-client-5.6',
          default => 'mysql-wsrep-client-5.6',
        }
      end
      should contain_class('mysql::client').with(
        'package_name' => pkg_name,
      )
    end
  end

  test_ubuntu_and_centos manifest
end
