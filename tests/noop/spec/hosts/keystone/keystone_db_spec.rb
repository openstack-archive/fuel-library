require 'spec_helper'
require 'shared-examples'
manifest = 'keystone/keystone_db.pp'
#TODO: uncomment in keystone module adaptation patch
describe manifest do
   #TODO: uncomment in keystone module adaptation patch
#  shared_examples 'catalog' do
#    keystone_db_user = 'keystone'
#    keystone_db_dbname = 'keystone'
#    keystone_db_password = Noop.hiera_structure 'keystone/db_password'
#    allowed_hosts = ['%',Noop.hostname]
#
#    it 'should declare keystone::db::mysql class with user,password,dbname' do
#      should contain_class('keystone::db::mysql').with(
#        'user' => keystone_db_user,
#        'password' => keystone_db_password,
#        'dbname' => keystone_db_dbname,
#        'allowed_hosts' => allowed_hosts,
#    end
#    allowed_hosts.each do |host|
#      it "should define openstacklib::db::mysql::host_access for #{keystone_db_dbname} DB for #{host}" do
#        should contain_openstacklib__db__mysql__host_access("#{keystone_db_dbname}_#{host}")
#      end
#    end
#  end # end of shared_examples
  test_ubuntu_and_centos manifest
end

