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
    'include apache
     class { keystone: admin_token => "dummy" }'
  end

  shared_examples_for 'apache serving keystone with mod_wsgi' do
    it { should contain_service('httpd').with_name(platform_parameters[:httpd_service_name]) }
    it { should contain_class('keystone::params') }
    it { should contain_class('apache') }
    it { should contain_class('apache::mod::wsgi') }
    it { should contain_class('keystone::db::sync') }

    describe 'with default parameters' do

      it { should contain_file("#{platform_parameters[:wsgi_script_path]}").with(
        'ensure'  => 'directory',
        'owner'   => 'keystone',
        'group'   => 'keystone',
        'require' => 'Package[httpd]'
      )}

      it { should contain_file('keystone_wsgi_admin').with(
        'ensure'  => 'file',
        'path'    => "#{platform_parameters[:wsgi_script_path]}/admin",
        'source'  => platform_parameters[:wsgi_script_source],
        'owner'   => 'keystone',
        'group'   => 'keystone',
        'mode'    => '0644',
        'require' => "File[#{platform_parameters[:wsgi_script_path]}]"
      )}

      it { should contain_file('keystone_wsgi_main').with(
        'ensure'  => 'file',
        'path'    => "#{platform_parameters[:wsgi_script_path]}/main",
        'source'  => platform_parameters[:wsgi_script_source],
        'owner'   => 'keystone',
        'group'   => 'keystone',
        'mode'    => '0644',
        'require' => "File[#{platform_parameters[:wsgi_script_path]}]"
      )}

      it { should contain_apache__vhost('keystone_wsgi_admin').with(
        'servername'                  => 'some.host.tld',
        'port'                        => '35357',
        'docroot'                     => "#{platform_parameters[:wsgi_script_path]}",
        'docroot_owner'               => 'keystone',
        'docroot_group'               => 'keystone',
        'ssl'                         => 'true',
        'wsgi_process_group'          => 'keystone',
        'wsgi_script_aliases'         => { '/' => "#{platform_parameters[:wsgi_script_path]}/admin" },
        'require'                     => ['Class[Apache::Mod::Wsgi]', 'File[keystone_wsgi_admin]']
      )}

      it { should contain_apache__vhost('keystone_wsgi_main').with(
        'servername'                  => 'some.host.tld',
        'port'                        => '5000',
        'docroot'                     => "#{platform_parameters[:wsgi_script_path]}",
        'docroot_owner'               => 'keystone',
        'docroot_group'               => 'keystone',
        'ssl'                         => 'true',
        'wsgi_daemon_process'         => 'keystone',
        'wsgi_process_group'          => 'keystone',
        'wsgi_script_aliases'         => { '/' => "#{platform_parameters[:wsgi_script_path]}/main" },
        'require'                     => ['Class[Apache::Mod::Wsgi]', 'File[keystone_wsgi_main]']
      )}
      it "should set keystone wsgi options" do
        contain_file('25-keystone_wsgi_main.conf').with_content(
          /^  WSGIDaemonProcess keystone group=keystone processes=1 threads=1 user=keystone$/
        )
      end
    end

    describe 'when overriding parameters using different ports' do
      let :params do
        {
          :servername  => 'dummy.host',
          :public_port => 12345,
          :admin_port  => 4142,
          :ssl         => false,
          :workers     => 37,
        }
      end

      it { should contain_apache__vhost('keystone_wsgi_admin').with(
        'servername'                  => 'dummy.host',
        'port'                        => '4142',
        'docroot'                     => "#{platform_parameters[:wsgi_script_path]}",
        'docroot_owner'               => 'keystone',
        'docroot_group'               => 'keystone',
        'ssl'                         => 'false',
        'wsgi_process_group'          => 'keystone',
        'wsgi_script_aliases'         => { '/' => "#{platform_parameters[:wsgi_script_path]}/admin" },
        'require'                     => ['Class[Apache::Mod::Wsgi]', 'File[keystone_wsgi_admin]']
      )}

      it { should contain_apache__vhost('keystone_wsgi_main').with(
        'servername'                  => 'dummy.host',
        'port'                        => '12345',
        'docroot'                     => "#{platform_parameters[:wsgi_script_path]}",
        'docroot_owner'               => 'keystone',
        'docroot_group'               => 'keystone',
        'ssl'                         => 'false',
        'wsgi_daemon_process'         => 'keystone',
        'wsgi_process_group'          => 'keystone',
        'wsgi_script_aliases'         => { '/' => "#{platform_parameters[:wsgi_script_path]}/main" },
        'require'                     => ['Class[Apache::Mod::Wsgi]', 'File[keystone_wsgi_main]']
      )}
      it "should set keystone wsgi options" do
        contain_file('25-keystone_wsgi_main.conf').with_content(
          /^  WSGIDaemonProcess keystone group=keystone processes=37 threads=1 user=keystone$/
        )
      end
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

      it { should_not contain_apache__vhost('keystone_wsgi_admin') }

      it { should contain_apache__vhost('keystone_wsgi_main').with(
        'servername'                  => 'dummy.host',
        'port'                        => '4242',
        'docroot'                     => "#{platform_parameters[:wsgi_script_path]}",
        'docroot_owner'               => 'keystone',
        'docroot_group'               => 'keystone',
        'ssl'                         => 'true',
        'wsgi_daemon_process'         => 'keystone',
        'wsgi_process_group'          => 'keystone',
        'wsgi_script_aliases'         => {
        '/main/endpoint'  => "#{platform_parameters[:wsgi_script_path]}/main",
        '/admin/endpoint' => "#{platform_parameters[:wsgi_script_path]}/admin"
      },
        'require'                     => ['Class[Apache::Mod::Wsgi]', 'File[keystone_wsgi_main]']
      )}
      it "should set keystone wsgi options" do
        contain_file('25-keystone_wsgi_main.conf').with_content(
          /^  WSGIDaemonProcess keystone group=keystone processes=37 threads=1 user=keystone$/
        )
      end
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
        :wsgi_script_path   => '/var/www/cgi-bin/keystone',
        :wsgi_script_source => 'puppet:///modules/keystone/httpd/keystone.py'
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
        :wsgi_script_path   => '/usr/lib/cgi-bin/keystone',
        :wsgi_script_source => '/usr/share/keystone/wsgi.py'
      }
    end

    it_configures 'apache serving keystone with mod_wsgi'
  end
end
