require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/neutron_db.pp'

describe manifest do
  #TODO: uncomment in neutron module adaptation patch
#  shared_examples 'catalog' do
#    allowed_hosts = ['%',Noop.hostname]
#    use_neutron = Noop.hiera 'use_neutron'
#
#    if use_neutron
#      neutron_db_user = 'neutron'
#      neutron_db_password = Noop.hiera'neutron_db_password'
#      neutron_db_dbname = 'neutron'
#
#      it 'should declare neutron::db::mysql class with user,password,dbname' do
#        should contain_class('neutron::db::mysql').with(
#          'user' => neutron_db_user,
#          'password' => neutron_db_password,
#          'allowed_hosts' => allowed_hosts,
#        )
#      end
#      allowed_hosts.each do |host|
#        it "should define openstacklib::db::mysql::host_access for #{neutron_db_dbname} DB for #{host}" do
#          should contain_openstacklib__db__mysql__host_access("#{neutron_db_dbname}_#{host}")
#        end
#      end
#    end
#  end # end of shared_examples
  test_ubuntu_and_centos manifest
end

