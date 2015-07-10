require 'spec_helper'
require 'shared-examples'
manifest = 'database/database.pp'

describe manifest do
  shared_examples 'catalog' do
    #nodes = Noop.hiera 'nodes'
    it { should contain_class('mysql::server').that_comes_before('Class[osnailyfacter::mysql_root]') }
    it { should contain_class('osnailyfacter::mysql_access') }
    it { should contain_class('osnailyfacter::mysql_root').that_comes_before('Exec[initial_access_config]') }
    it { should contain_class('openstack::galera::status').that_comes_before('Haproxy_backend_status[mysql]') }
    it { should contain_haproxy_backend_status('mysql').that_comes_before('Class[osnailyfacter::mysql_access]') }
    it { should contain_package('socat').that_comes_before('Class[mysql::server]') }
  end

  test_ubuntu_and_centos manifest
end

