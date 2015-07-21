require 'spec_helper'

describe 'keystone::wsgi::apache' do

  let :global_facts do
    {
      :processorcount => 42,
      :concat_basedir => '/var/lib/puppet/concat',
      :fqdn           => 'some.host.tld'
    }
  end

  let :pre_condition do
    [
     'class { keystone: admin_token => "dummy", service_name => "httpd", enable_ssl => true }'
    ]
  end

  shared_examples_for 'apache serving keystone with mod_wsgi' do
    it { is_expected.to contain_service('httpd').with_name(platform_parameters[:httpd_service_name]) }
    it { is_expected.to contain_class('keystone::params') }
    it { is_expected.to contain_class('apache') }
    it { is_expected.to contain_class('apache::mod::wsgi') }
    it { is_expected.to contain_class('keystone::db::sync') }

    describe 'with default parameters' do

      it { is_expected.to contain_file("#{platform_parameters[:wsgi_script_path]}").with(
        'ensure'  => 'directory',
        'owner'   => 'keystone',
        'group'   => 'keystone',
        'require' => 'Package[httpd]'
      )}

      it { is_expected.to contain_file('keystone_wsgi_admin').with(
        'ensure'  => 'file',
        'path'    => "#{platform_parameters[:wsgi_script_path]}/admin",
        'source'  => platform_parameters[:wsgi_script_source],
        'owner'   => 'keystone',
        'group'   => 'keystone',
        'mode'    => '0644',
        'require' => ["File[#{platform_parameters[:wsgi_script_path]}]", "Package[keystone]"]
      )}

      it { is_expected.to contain_file('keystone_wsgi_main').with(
        'ensure'  => 'file',
        'path'    => "#{platform_parameters[:wsgi_script_path]}/main",
        'source'  => platform_parameters[:wsgi_script_source],
        'owner'   => 'keystone',
        'group'   => 'keystone',
        'mode'    => '0644',
        'require' => ["File[#{platform_parameters[:wsgi_script_path]}]", "Package[keystone]"]
      )}

      it { is_expected.to contain_apache__vhost('keystone_wsgi_admin').with(
        'servername'                  => 'some.host.tld',
        'ip'                          => nil,
        'port'                        => '35357',
        'docroot'                     => "#{platform_parameters[:wsgi_script_path]}",
        'docroot_owner'               => 'keystone',
        'docroot_group'               => 'keystone',
        'ssl'                         => 'true',
        'wsgi_daemon_process'         => 'keystone_admin',
        'wsgi_daemon_process_options' => {
          'user'         => 'keystone',
          'group'        => 'keystone',
          'processes'    => '1',
          'threads'      => '42',
          'display-name' => 'keystone-admin',
        },
        'wsgi_process_group'          => 'keystone_admin',
        'wsgi_script_aliases'         => { '/' => "#{platform_parameters[:wsgi_script_path]}/admin" },
        'require'                     => 'File[keystone_wsgi_admin]'
      )}

      it { is_expected.to contain_apache__vhost('keystone_wsgi_main').with(
        'servername'                  => 'some.host.tld',
        'ip'                          => nil,
        'port'                        => '5000',
        'docroot'                     => "#{platform_parameters[:wsgi_script_path]}",
        'docroot_owner'               => 'keystone',
        'docroot_group'               => 'keystone',
        'ssl'                         => 'true',
        'wsgi_daemon_process'         => 'keystone_main',
        'wsgi_daemon_process_options' => {
          'user'         => 'keystone',
          'group'        => 'keystone',
          'processes'    => '1',
          'threads'      => '42',
          'display-name' => 'keystone-main',
        },
        'wsgi_process_group'          => 'keystone_main',
        'wsgi_script_aliases'         => { '/' => "#{platform_parameters[:wsgi_script_path]}/main" },
        'require'                     => 'File[keystone_wsgi_main]'
      )}
      it { is_expected.to contain_file("#{platform_parameters[:httpd_ports_file]}") }
    end

    describe 'when overriding parameters using different ports' do
      let :params do
        {
          :servername  => 'dummy.host',
          :bind_host   => '10.42.51.1',
          :public_port => 12345,
          :admin_port  => 4142,
          :ssl         => false,
          :workers     => 37,
        }
      end

      it { is_expected.to contain_apache__vhost('keystone_wsgi_admin').with(
        'servername'                  => 'dummy.host',
        'ip'                          => '10.42.51.1',
        'port'                        => '4142',
        'docroot'                     => "#{platform_parameters[:wsgi_script_path]}",
        'docroot_owner'               => 'keystone',
        'docroot_group'               => 'keystone',
        'ssl'                         => 'false',
        'wsgi_daemon_process'         => 'keystone_admin',
        'wsgi_daemon_process_options' => {
                  'user' => 'keystone',
                 'group' => 'keystone',
             'processes' => '37',
               'threads' => '42',
          'display-name' => 'keystone-admin',
        },
        'wsgi_process_group'          => 'keystone_admin',
        'wsgi_script_aliases'         => { '/' => "#{platform_parameters[:wsgi_script_path]}/admin" },
        'require'                     => 'File[keystone_wsgi_admin]'
      )}

      it { is_expected.to contain_apache__vhost('keystone_wsgi_main').with(
        'servername'                  => 'dummy.host',
        'ip'                          => '10.42.51.1',
        'port'                        => '12345',
        'docroot'                     => "#{platform_parameters[:wsgi_script_path]}",
        'docroot_owner'               => 'keystone',
        'docroot_group'               => 'keystone',
        'ssl'                         => 'false',
        'wsgi_daemon_process'         => 'keystone_main',
        'wsgi_daemon_process_options' => {
                  'user' => 'keystone',
                 'group' => 'keystone',
             'processes' => '37',
               'threads' => '42',
          'display-name' => 'keystone-main',
        },
        'wsgi_process_group'          => 'keystone_main',
        'wsgi_script_aliases'         => { '/' => "#{platform_parameters[:wsgi_script_path]}/main" },
        'require'                     => 'File[keystone_wsgi_main]'
      )}

      it { is_expected.to contain_file("#{platform_parameters[:httpd_ports_file]}") }
    end

    describe 'when overriding parameters using same port' do
      let :params do
        {
          :servername  => 'dummy.host',
          :public_port => 4242,
          :admin_port  => 4242,
          :public_path => '/main/endpoint/',
          :admin_path  => '/admin/endpoint/',
          :ssl         => true,
          :workers     => 37,
        }
      end

      it { is_expected.to_not contain_apache__vhost('keystone_wsgi_admin') }

      it { is_expected.to contain_apache__vhost('keystone_wsgi_main').with(
        'servername'                  => 'dummy.host',
        'ip'                          => nil,
        'port'                        => '4242',
        'docroot'                     => "#{platform_parameters[:wsgi_script_path]}",
        'docroot_owner'               => 'keystone',
        'docroot_group'               => 'keystone',
        'ssl'                         => 'true',
        'wsgi_daemon_process'         => 'keystone_main',
        'wsgi_daemon_process_options' => {
                  'user' => 'keystone',
                 'group' => 'keystone',
             'processes' => '37',
               'threads' => '42',
          'display-name' => 'keystone-main',
        },
        'wsgi_process_group'          => 'keystone_main',
        'wsgi_script_aliases'         => {
        '/main/endpoint'  => "#{platform_parameters[:wsgi_script_path]}/main",
        '/admin/endpoint' => "#{platform_parameters[:wsgi_script_path]}/admin"
        },
        'require'                     => 'File[keystone_wsgi_main]'
      )}
    end

    describe 'when overriding parameters using same port and same path' do
      let :params do
        {
          :servername  => 'dummy.host',
          :public_port => 4242,
          :admin_port  => 4242,
          :public_path => '/endpoint/',
          :admin_path  => '/endpoint/',
          :ssl         => true,
          :workers     => 37,
        }
      end

      it_raises 'a Puppet::Error', /When using the same port for public & private endpoints, public_path and admin_path should be different\./
    end

    describe 'when overriding parameters using symlink and custom file source' do
      let :params do
        {
          :wsgi_script_ensure => 'link',
          :wsgi_script_source => '/opt/keystone/httpd/keystone.py',
        }
      end

      it { is_expected.to contain_file('keystone_wsgi_admin').with(
        'ensure'  => 'link',
        'path'    => "#{platform_parameters[:wsgi_script_path]}/admin",
        'target'  => '/opt/keystone/httpd/keystone.py',
        'owner'   => 'keystone',
        'group'   => 'keystone',
        'mode'    => '0644',
        'require' => ["File[#{platform_parameters[:wsgi_script_path]}]", "Package[keystone]"]
      )}

      it { is_expected.to contain_file('keystone_wsgi_main').with(
        'ensure'  => 'link',
        'path'    => "#{platform_parameters[:wsgi_script_path]}/main",
        'target'  => '/opt/keystone/httpd/keystone.py',
        'owner'   => 'keystone',
        'group'   => 'keystone',
        'mode'    => '0644',
        'require' => ["File[#{platform_parameters[:wsgi_script_path]}]", "Package[keystone]"]
      )}
    end
  end

  context 'on RedHat platforms' do
    let :facts do
      global_facts.merge({
        :osfamily               => 'RedHat',
        :operatingsystemrelease => '6.0'
      })
    end

    let :platform_parameters do
      {
        :httpd_service_name => 'httpd',
        :httpd_ports_file   => '/etc/httpd/conf/ports.conf',
        :wsgi_script_path   => '/var/www/cgi-bin/keystone',
        :wsgi_script_source => '/usr/share/keystone/keystone.wsgi'
      }
    end

    it_configures 'apache serving keystone with mod_wsgi'
  end

  context 'on Debian platforms' do
    let :facts do
      global_facts.merge({
        :osfamily               => 'Debian',
        :operatingsystem        => 'Debian',
        :operatingsystemrelease => '7.0'
      })
    end

    let :platform_parameters do
      {
        :httpd_service_name => 'apache2',
        :httpd_ports_file   => '/etc/apache2/ports.conf',
        :wsgi_script_path   => '/usr/lib/cgi-bin/keystone',
        :wsgi_script_source => '/usr/share/keystone/wsgi.py'
      }
    end

    it_configures 'apache serving keystone with mod_wsgi'
  end
end
