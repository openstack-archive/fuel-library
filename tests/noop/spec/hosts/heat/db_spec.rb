# ROLE: primary-controller

require 'spec_helper'
require 'shared-examples'
manifest = 'heat/db.pp'

describe manifest do
  shared_examples 'catalog' do
    heat_db_user = 'heat'
    heat_db_dbname = 'heat'
    heat_db_password = Noop.hiera_structure 'heat/db_password'
    allowed_hosts = ['localhost','127.0.0.1','%']

    it 'should install proper mysql-client' do
      if facts[:osfamily] == 'RedHat'
        pkg_name = 'MySQL-client-wsrep'
      elsif facts[:osfamily] == 'Debian'
        pkg_name = 'mysql-wsrep-client-5.6'
      end
      should contain_class('mysql::client').with(
        'package_name' => pkg_name,
      )
    end
    it 'should declare heat::db::mysql class with user,password,dbname' do
      should contain_class('heat::db::mysql').with(
        'user' => heat_db_user,
        'password' => heat_db_password,
        'dbname' => heat_db_dbname,
        'allowed_hosts' => allowed_hosts,
      )
    end
    allowed_hosts.each do |host|
      it "should define openstacklib::db::mysql::host_access for #{heat_db_dbname} DB for #{host}" do
        should contain_openstacklib__db__mysql__host_access("#{heat_db_dbname}_#{host}")
      end
    end
  end
  test_ubuntu_and_centos manifest
end
