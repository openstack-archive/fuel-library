require 'spec_helper'
require 'shared-examples'
manifest = 'ironic/ironic_db.pp'

describe manifest do
  shared_examples 'catalog' do
    ironic_db_user = 'ironic'
    ironic_db_password = Noop.hiera_structure 'ironic/db_password'
    ironic_db_dbname = 'ironic'
    node_name = Noop.hiera_structure 'node_name'
    allowed_hosts = [node_name,'localhost','127.0.0.1','%']

    ironic_enabled = Noop.hiera_structure 'ironic/enabled'

    if ironic_enabled
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
  end # end of shared_examples
  test_ubuntu_and_centos manifest
end
