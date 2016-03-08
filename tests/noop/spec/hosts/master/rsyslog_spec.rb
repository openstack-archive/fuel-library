require 'spec_helper'
require 'shared-examples'
manifest = 'master/rsyslog.pp'

# HIERA: master
# FACTS: master_centos7 master_centos6

describe manifest do
  shared_examples 'catalog' do

    it 'should correctly declare rsyslog class' do
      parameters = {
        :relp_package_name   => false,
        :gnutls_package_name => false,
        :mysql_package_name  => false,
        :pgsql_package_name  => false,
        :show_timestamp      => true,
      }
      is_expected.to contain_class('rsyslog').with parameters
    end

    it 'should correctly declare openstack::logging class' do
      parameters = {
        :role  => 'server',
        :proto => 'both',
        :port  => '514'
      }
      is_expected.to contain_class('openstack::logging').with parameters
    end

  end
  run_test manifest
end
