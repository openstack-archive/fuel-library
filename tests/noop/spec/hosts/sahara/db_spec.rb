require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/db.pp'

describe manifest do
  shared_examples 'catalog' do
    sahara_db_user = 'sahara'
    sahara_db_dbname = 'sahara'
    sahara_db_password = Noop.hiera_structure 'sahara/db_password'
    allowed_hosts = [Noop.hostname,'localhost','127.0.0.1','%']

    it 'should declare sahara::db::mysql class with user,password,dbname' do
      should contain_class('sahara::db::mysql').with(
        'user' => sahara_db_user,
        'password' => sahara_db_password,
        'dbname' => sahara_db_dbname,
        'allowed_hosts' => allowed_hosts,
      )
    end
    allowed_hosts.each do |host|
      it "should define openstacklib::db::mysql::host_access for #{sahara_db_dbname} DB for #{host}" do
        should contain_openstacklib__db__mysql__host_access("#{sahara_db_dbname}_#{host}")
      end
    end
  end
 test_ubuntu_and_centos manifest
end
