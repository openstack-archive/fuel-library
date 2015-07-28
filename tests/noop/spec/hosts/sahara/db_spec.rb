require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/db.pp'

describe manifest do

  shared_examples 'catalog' do
    it 'should install proper mysql-client' do
      if facts[:osfamily] == 'RedHat'
        pkg_name = 'MySQL-client-wsrep'
      elsif facts[:osfamily] == 'Debian'
        pkg_name = 'mysql-client-5.6'
      end
      should contain_package('mysql-client').with(
        'name' => pkg_name,
      )
    end
  end

  test_ubuntu_and_centos manifest
end
