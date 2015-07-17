require 'spec_helper'

describe 'ceilometer::wsgi::apache' do

  let :global_facts do
    {
      :processorcount => 42,
      :concat_basedir => '/var/lib/puppet/concat',
      :fqdn           => 'some.host.tld'
    }
  end

  let :pre_condition do
    "class { 'ceilometer': metering_secret => 's3cr3t' }"
  end

  shared_examples_for 'apache serving ceilometer with mod_wsgi' do
    it { is_expected.to contain_service('httpd').with_name(platform_parameters[:httpd_service_name]) }
    it { is_expected.to contain_class('ceilometer::params') }
    it { is_expected.to contain_class('apache') }
    it { is_expected.to contain_class('apache::mod::wsgi') }

    describe 'with default parameters' do

      it { is_expected.to contain_file("#{platform_parameters[:wsgi_script_path]}").with(
        'ensure'  => 'directory',
        'owner'   => 'ceilometer',
        'group'   => 'ceilometer',
        'require' => 'Package[httpd]'
      )}


      it { is_expected.to contain_file('ceilometer_wsgi').with(
        'ensure'  => 'file',
        'path'    => "#{platform_parameters[:wsgi_script_path]}/app",
        'source'  => platform_parameters[:wsgi_script_source],
        'owner'   => 'ceilometer',
        'group'   => 'ceilometer',
        'mode'    => '0644'
      )}
      it { is_expected.to contain_file('ceilometer_wsgi').that_requires("File[#{platform_parameters[:wsgi_script_path]}]") }

      it { is_expected.to contain_apache__vhost('ceilometer_wsgi').with(
        'servername'                  => 'some.host.tld',
        'ip'                          => nil,
        'port'                        => '8777',
        'docroot'                     => "#{platform_parameters[:wsgi_script_path]}",
        'docroot_owner'               => 'ceilometer',
        'docroot_group'               => 'ceilometer',
        'ssl'                         => 'true',
        'wsgi_daemon_process'         => 'ceilometer',
        'wsgi_process_group'          => 'ceilometer',
        'wsgi_script_aliases'         => { '/' => "#{platform_parameters[:wsgi_script_path]}/app" },
        'require'                     => 'File[ceilometer_wsgi]'
      )}
      it { is_expected.to contain_file("#{platform_parameters[:httpd_ports_file]}") }
    end

    describe 'when overriding parameters using different ports' do
      let :params do
        {
          :servername  => 'dummy.host',
          :bind_host   => '10.42.51.1',
          :port        => 12345,
          :ssl         => false,
          :workers     => 37,
        }
      end

      it { is_expected.to contain_apache__vhost('ceilometer_wsgi').with(
        'servername'                  => 'dummy.host',
        'ip'                          => '10.42.51.1',
        'port'                        => '12345',
        'docroot'                     => "#{platform_parameters[:wsgi_script_path]}",
        'docroot_owner'               => 'ceilometer',
        'docroot_group'               => 'ceilometer',
        'ssl'                         => 'false',
        'wsgi_daemon_process'         => 'ceilometer',
        'wsgi_process_group'          => 'ceilometer',
        'wsgi_script_aliases'         => { '/' => "#{platform_parameters[:wsgi_script_path]}/app" },
        'require'                     => 'File[ceilometer_wsgi]'
      )}

      it { is_expected.to contain_file("#{platform_parameters[:httpd_ports_file]}") }
    end
  end

  context 'on RedHat platforms' do
    let :facts do
      global_facts.merge({
        :osfamily               => 'RedHat',
        :operatingsystemrelease => '7.0'
      })
    end

    let :platform_parameters do
      {
        :httpd_service_name => 'httpd',
        :httpd_ports_file   => '/etc/httpd/conf/ports.conf',
        :wsgi_script_path   => '/var/www/cgi-bin/ceilometer',
        :wsgi_script_source => '/usr/lib/python2.7/site-packages/ceilometer/api/app.wsgi'
      }
    end

    it_configures 'apache serving ceilometer with mod_wsgi'
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
        :wsgi_script_path   => '/usr/lib/cgi-bin/ceilometer',
        :wsgi_script_source => '/usr/share/ceilometer/app.wsgi'
      }
    end

    it_configures 'apache serving ceilometer with mod_wsgi'
  end
end
