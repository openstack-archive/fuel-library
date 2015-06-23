require 'spec_helper'
require 'shared-examples'
manifest = 'database/database.pp'

describe manifest do
  shared_examples 'catalog' do
    keystone_db_user = 'keystone'
    keystone_db_dbname = 'keystone'
    keystone_db_password = Noop.hiera_structure 'keystone/db_password'
    glance_db_user = 'glance'
    glance_db_password = Noop.hiera_structure 'glance/db_password'
    glance_db_dbname = 'glance'
    nova_db_user = 'nova'
    nova_db_password = Noop.hiera_structure 'nova/db_password'
    nova_db_dbname = 'nova'
    cinder_db_user = 'cinder'
    cinder_db_password = Noop.hiera_structure 'cinder/db_password'
    cinder_db_dbname = 'cinder'
    hostname = Noop.hostname
    allowed_hosts = ['%',Noop.hostname]
    use_neutron = Noop.hiera 'use_neutron'

    it 'should declare keystone::db::mysql class with user,password,dbname' do
        should contain_class('keystone::db::mysql').with(
            'user' => keystone_db_user,
            'password' => keystone_db_password,
            'dbname' => keystone_db_dbname,
            'allowed_hosts' => allowed_hosts,
        )
    end
    allowed_hosts.each do |host|
      it "should define openstacklib::db::mysql::host_access for #{keystone_db_dbname} DB for #{host}" do
        should contain_openstacklib__db__mysql__host_access("#{keystone_db_dbname}_#{host}")
      end
    end
    it 'should declare glance:db::mysql class with user,password,dbname' do
        should contain_class('glance::db::mysql').with(
            'user' => glance_db_user,
            'password' => glance_db_password,
            'dbname' => glance_db_dbname,
            'allowed_hosts' => allowed_hosts,
        )
    end
    #TODO: uncomment in glance module adaptation patch
#    allowed_hosts.each do |host|
#      it "should define openstacklib::db::mysql::host_access for #{glance_db_dbname} DB for #{host}" do
#        should contain_openstacklib__db__mysql__host_access("#{glance_db_dbname}_#{host}")
#      end
#    end
    it 'should declare nova::db::mysql class with user,password,dbname' do
        should contain_class('nova::db::mysql').with(
            'user' => nova_db_user,
            'password' => nova_db_password,
            'dbname' => nova_db_dbname,
            'allowed_hosts' => allowed_hosts,
        )
    end
     #TODO: uncomment in cinder module adaptation patch
#    allowed_hosts.each do |host|
#      it "should define openstacklib::db::mysql::host_access for #{nova_db_dbname} DB for #{host}" do
#        should contain_openstacklib__db__mysql__host_access("#{nova_db_dbname}_#{host}")
#      end
#    end
    it 'should declare cinder::db::mysql class with user,password,dbname' do
        should contain_class('cinder::db::mysql').with(
            'user' => cinder_db_user,
            'password' => cinder_db_password,
            'dbname' => cinder_db_dbname,
            'allowed_hosts' => allowed_hosts,
        )
    end
     #TODO: uncomment in cinder module adaptation patch
#    allowed_hosts.each do |host|
#      it "should define openstacklib::db::mysql::host_access for #{cinder_db_dbname} DB for #{host}" do
#        should contain_openstacklib__db__mysql__host_access("#{cinder_db_dbname}_#{host}")
#      end
#    end
    if use_neutron
        neutron_db_user = 'neutron'
        neutron_db_password = Noop.hiera'neutron_db_password'
        neutron_db_dbname = 'neutron'
        it 'should declare neutron::db::mysql class with user,password,dbname' do
            should contain_class('neutron::db::mysql').with(
                'user' => neutron_db_user,
                'password' => neutron_db_password,
                'dbname' => neutron_db_dbname,
                'allowed_hosts' => allowed_hosts,
            )
        end
             #TODO: uncomment in neutron module adaptation patch
#            allowed_hosts.each do |host|
#              it "should define openstacklib::db::mysql::host_access for #{neutron_db_dbname} DB for #{host}" do
#                should contain_openstacklib__db__mysql__host_access("#{neutron_db_dbname}_#{host}")
#              end
#            end
    end

  end # end of shared_examples
  test_ubuntu_and_centos manifest
end
