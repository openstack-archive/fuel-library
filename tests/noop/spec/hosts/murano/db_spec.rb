require 'spec_helper'
require 'shared-examples'
manifest = 'murano/db.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  shared_examples 'catalog' do
    murano_enabled = task.hiera_structure('murano/enabled', false)

    it 'should install proper mysql-client', :if => murano_enabled do
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

