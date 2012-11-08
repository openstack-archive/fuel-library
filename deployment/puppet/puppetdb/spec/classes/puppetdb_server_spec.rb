require 'spec_helper'

describe 'puppetdb::server', :type => :class do

    context 'using hsqldb' do
        let (:params) do
            {
                :database  => 'embedded',
                :version   => 'present'
            }
        end
        it {
            should contain_package('puppetdb').with(
                :ensure => params[:version],
                :notify  => 'Service[puppetdb]'
            )
            should contain_file('/etc/puppetdb/conf.d/database.ini').with(
                :ensure  => 'file',
                :require => 'Package[puppetdb]'
            )
            should contain_service('puppetdb').with(
                :ensure  => 'running',
                :enable  => 'true',
                :require => 'File[/etc/puppetdb/conf.d/database.ini]'
            )
            should contain_ini_setting('puppetdb_classname').with(
                :ensure   => 'present',
                :section  => 'database',
                :setting  => 'classname',
                :value    => 'org.hsqldb.jdbcDriver',
                :require  => 'File[/etc/puppetdb/conf.d/database.ini]',
                :notify   => 'Service[puppetdb]',
                :path     => '/etc/puppetdb/conf.d/database.ini'
            )
            should contain_ini_setting('puppetdb_subprotocol').with(
                :ensure   => 'present',
                :section  => 'database',
                :setting  => 'subprotocol',
                :value    => 'hsqldb',
                :require  => 'File[/etc/puppetdb/conf.d/database.ini]',
                :notify   => 'Service[puppetdb]',
                :path     => '/etc/puppetdb/conf.d/database.ini'
            )
            should contain_ini_setting('puppetdb_pgs').with(
                :ensure   => 'present',
                :section  => 'database',
                :setting  => 'syntax_pgs',
                :value    => 'true',
                :require  => 'File[/etc/puppetdb/conf.d/database.ini]',
                :notify   => 'Service[puppetdb]',
                :path     => '/etc/puppetdb/conf.d/database.ini'
            )
            should contain_ini_setting('puppetdb_subname').with(
                :ensure   => 'present',
                :section  => 'database',
                :setting  => 'subname',
                :value    => 'file:/usr/share/puppetdb/db/db;hsqldb.tx=mvcc;sql.syntax_pgs=true',
                :require  => 'File[/etc/puppetdb/conf.d/database.ini]',
                :notify   => 'Service[puppetdb]',
                :path     => '/etc/puppetdb/conf.d/database.ini'
            )
            should contain_ini_setting('puppetdb_gc_interval').with(
                :ensure   => 'present',
                :section  => 'database',
                :setting  => 'gc-interval',
                :value    => '60',
                :require  => 'File[/etc/puppetdb/conf.d/database.ini]',
                :notify   => 'Service[puppetdb]',
                :path     => '/etc/puppetdb/conf.d/database.ini'
            )
        }
    end

    context 'using postgres' do
        let (:params) do
            {
                :database  => 'postgres',
                :version   => 'present'
            }
        end
        it {
            should contain_package('puppetdb').with(
                :ensure => params[:version],
                :notify  => 'Service[puppetdb]'
            )
            should contain_file('/etc/puppetdb/conf.d/database.ini').with(
                :ensure  => 'file',
                :require => 'Package[puppetdb]'
            )
            should contain_service('puppetdb').with(
                :ensure  => 'running',
                :enable  => 'true',
                :require => 'File[/etc/puppetdb/conf.d/database.ini]'
            )
            should contain_ini_setting('puppetdb_psdatabase_username').with(
                :ensure   => 'present',
                :section  => 'database',
                :setting  => 'username',
                :value    => 'puppetdb',
                :require  => 'File[/etc/puppetdb/conf.d/database.ini]',
                :notify   => 'Service[puppetdb]',
                :path     => '/etc/puppetdb/conf.d/database.ini'
            )
            should contain_ini_setting('puppetdb_psdatabase_password').with(
                :ensure   => 'present',
                :section  => 'database',
                :setting  => 'password',
                :value    => 'puppetdb',
                :require  => 'File[/etc/puppetdb/conf.d/database.ini]',
                :notify   => 'Service[puppetdb]',
                :path     => '/etc/puppetdb/conf.d/database.ini'
            )
            should contain_ini_setting('puppetdb_classname').with(
                :ensure   => 'present',
                :section  => 'database',
                :setting  => 'classname',
                :value    => 'org.postgresql.Driver',
                :require  => 'File[/etc/puppetdb/conf.d/database.ini]',
                :notify   => 'Service[puppetdb]',
                :path     => '/etc/puppetdb/conf.d/database.ini'
            )
            should contain_ini_setting('puppetdb_subprotocol').with(
                :ensure   => 'present',
                :section  => 'database',
                :setting  => 'subprotocol',
                :value    => 'postgresql',
                :require  => 'File[/etc/puppetdb/conf.d/database.ini]',
                :notify   => 'Service[puppetdb]',
                :path     => '/etc/puppetdb/conf.d/database.ini'
            )
            should contain_ini_setting('puppetdb_pgs').with(
                :ensure   => 'present',
                :section  => 'database',
                :setting  => 'syntax_pgs',
                :value    => 'true',
                :require  => 'File[/etc/puppetdb/conf.d/database.ini]',
                :notify   => 'Service[puppetdb]',
                :path     => '/etc/puppetdb/conf.d/database.ini'
            )
            should contain_ini_setting('puppetdb_subname').with(
                :ensure   => 'present',
                :section  => 'database',
                :setting  => 'subname',
                :value    => '//localhost:5432/puppetdb',
                :require  => 'File[/etc/puppetdb/conf.d/database.ini]',
                :notify   => 'Service[puppetdb]',
                :path     => '/etc/puppetdb/conf.d/database.ini'
            )
            should contain_ini_setting('puppetdb_gc_interval').with(
                :ensure   => 'present',
                :section  => 'database',
                :setting  => 'gc-interval',
                :value    => '60',
                :require  => 'File[/etc/puppetdb/conf.d/database.ini]',
                :notify   => 'Service[puppetdb]',
                :path     => '/etc/puppetdb/conf.d/database.ini'
            )
        }
    end
end