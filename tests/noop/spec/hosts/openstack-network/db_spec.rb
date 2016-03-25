# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/db.pp'

describe manifest do
  #TODO: uncomment in neutron module adaptation patch
  shared_examples 'catalog' do
    use_neutron = Noop.hiera 'use_neutron'
    allowed_hosts = ['localhost','127.0.0.1','%']

    if use_neutron
      neutron_db_user = 'neutron'
      neutron_db_password = Noop.hiera'neutron_db_password'
      neutron_db_dbname = 'neutron'

      it 'should install proper mysql-client' do
        if facts[:osfamily] == 'RedHat'
          pkg_name = 'MySQL-client-wsrep'
        elsif facts[:osfamily] == 'Debian'
          pkg_name = 'mysql-client-5.6'
        end
        should contain_class('mysql::client').with(
          'package_name' => pkg_name,
        )
      end

      it 'should declare neutron::db::mysql class with user,password,dbname' do
        should contain_class('neutron::db::mysql').with(
          'user' => neutron_db_user,
          'password' => neutron_db_password,
          'allowed_hosts' => allowed_hosts,
        )
      end
      #TODO: uncomment in keystone module adaptation patch
#      allowed_hosts.each do |host|
#        it "should define openstacklib::db::mysql::host_access for #{neutron_db_dbname} DB for #{host}" do
#          should contain_openstacklib__db__mysql__host_access("#{neutron_db_dbname}_#{host}")
#        end
#      end
    end
  end # end of shared_examples
  test_ubuntu_and_centos manifest
end
