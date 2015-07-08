require 'spec_helper'
require 'shared-examples'
manifest = 'heat/heat_db.pp'

describe manifest do
  shared_examples 'catalog' do

    it 'should contain openstack::heat class with db_allowed_hosts parameter' do
      hostname = Noop.hostname
      db_allowed_hosts = [ hostname, 'localhost', '127.0.0.1', '%' ]
      should contain_class('heat::db::mysql').with('allowed_hosts' => db_allowed_hosts)
    end

  end # end of shared_examples
  test_ubuntu_and_centos manifest
end

