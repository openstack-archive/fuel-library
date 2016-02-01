require 'spec_helper'

describe 'openstack::galera::client' do

  shared_examples_for 'openstack::galera::client config' do
    context 'default parameters' do
      let(:mysql_client_name) do
        case facts[:osfamily]
        when 'Debian'
          'mysql-client-5.6'
        when 'RedHat'
          'MySQL-client-wsrep'
        else
          'mysql-client'
        end
      end

      it 'contains galera client' do
        should contain_class('mysql::client').with(
          :package_name => mysql_client_name
        )
      end
    end

    context 'using percona' do
      let(:params) do
        { :custom_setup_class => 'percona' }
      end

      let(:mysql_client_name) do
        case facts[:osfamily]
        when 'Debian'
          'percona-xtradb-cluster-client-5.5'
        else
          false
        end
      end

      it 'contains galera client' do
        if (mysql_client_name)
          should contain_class('mysql::client').with(
            :package_name => mysql_client_name
          )
        else
          expect { catalogue }.to raise_error(Puppet::Error, /Unsupported osfamily/)
        end
      end
    end

    context 'using percona packages' do
      let(:params) do
        { :custom_setup_class => 'percona_packages' }
      end

      let(:mysql_client_name) do
        case facts[:osfamily]
        when 'Debian'
          'percona-xtradb-cluster-client-5.6'
        when 'RedHat'
          'Percona-XtraDB-Cluster-client-56'
        else
          false
        end
      end

      it 'contains galera client' do
        if (mysql_client_name)
          should contain_class('mysql::client').with(
            :package_name => mysql_client_name
          )
        else
          expect { catalogue }.to raise_error(Puppet::Error, /Unsupported osfamily/)
        end
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Debian',
      }
    end

    it_configures 'openstack::galera::client config'
  end

  context 'on RedHat platforms' do
    let :facts do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
      }
    end

    it_configures 'openstack::galera::client config'
  end

end
