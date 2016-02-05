require 'spec_helper'
require 'shared-examples'
manifest = 'ironic/db.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  shared_examples 'catalog' do
    ironic_enabled = task.hiera_structure 'ironic/enabled'

    if ironic_enabled
      ironic_db_user = 'ironic'
      ironic_db_dbname = 'ironic'
      ironic_db_password = task.hiera_structure 'ironic/db_password'
      allowed_hosts = [task.hostname,'localhost','127.0.0.1','%']

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
      it 'should declare ironic::db::mysql class with user,password,dbname' do
        should contain_class('ironic::db::mysql').with(
          'user' => ironic_db_user,
          'password' => ironic_db_password,
          'dbname' => ironic_db_dbname,
          'allowed_hosts' => allowed_hosts,
        )
      end
      allowed_hosts.each do |host|
        it "should define openstacklib::db::mysql::host_access for #{ironic_db_dbname} DB for #{host}" do
          should contain_openstacklib__db__mysql__host_access("#{ironic_db_dbname}_#{host}")
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end
