require 'spec_helper'
require 'shared-examples'
manifest = 'glance/glance_db.pp'

describe manifest do
#TODO: uncomment in glance module adaptation patch
#  shared_examples 'catalog' do
#    glance_db_user = 'glance'
#    glance_db_dbname = 'keystone'
#    glance_db_password = Noop.hiera_structure 'glance/db_password'
#    allowed_hosts = ['%',Noop.hostname]
#
#    it 'should declare glance::db::mysql class with user,password,dbname' do
#      should contain_class('glance::db::mysql').with(
#        'user' => glance_db_user,
#        'password' => glance_db_password,
#        'dbname' => glance_db_dbname,
#        'allowed_hosts' => allowed_hosts,
#    end
#    allowed_hosts.each do |host|
#      it "should define openstacklib::db::mysql::host_access for #{glance_db_dbname} DB for #{host}" do
#        should contain_openstacklib__db__mysql__host_access("#{glance_db_dbname}_#{host}")
#      end
#    end
#  end # end of shared_examples
  test_ubuntu_and_centos manifest
end

