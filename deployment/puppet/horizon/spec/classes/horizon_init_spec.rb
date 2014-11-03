require 'spec_helper'

describe 'horizon' do

  let :params do
    { 'secret_key' => 'elj1IWiLoWHgcyYxFVLj7cM5rGOOxWl0',
      'fqdn'       => '*' }
  end

  let :pre_condition do
    'include apache'
  end

  let :fixtures_path do
    File.expand_path(File.join(__FILE__, '..', '..', 'fixtures'))
  end

  let :facts do
    { :concat_basedir => '/var/lib/puppet/concat',
      :fqdn           => 'some.host.tld'
    }
  end

  shared_examples 'horizon' do

    context 'with default parameters' do
      it {
          should contain_package('python-lesscpy').with_ensure('present')
          should contain_package('horizon').with_ensure('present')
      }
      it { should contain_exec('refresh_horizon_django_cache').with({
          :command     => '/usr/share/openstack-dashboard/manage.py compress',
          :refreshonly => true,
      })}

      it 'configures apache' do
        should contain_class('horizon::wsgi::apache').with({
          :servername   => 'some.host.tld',
          :listen_ssl   => false,
          :servername   => 'some.host.tld',
          :extra_params => {},
        })
      end

      it 'generates local_settings.py' do
        verify_contents(subject, platforms_params[:config_file], [
          'DEBUG = False',
          "ALLOWED_HOSTS = ['*', ]",
          "SECRET_KEY = 'elj1IWiLoWHgcyYxFVLj7cM5rGOOxWl0'",
          'OPENSTACK_KEYSTONE_URL = "http://127.0.0.1:5000/v2.0"',
          'OPENSTACK_KEYSTONE_DEFAULT_ROLE = "_member_"',
          "    'can_set_mount_point': True,",
          "    'can_set_password': False,",
          "    'enable_lb': False,",
          "    'enable_firewall': False,",
          "    'enable_quotas': True,",
          "    'enable_security_group': True,",
          "    'enable_vpn': False,",
          'API_RESULT_LIMIT = 1000',
          "LOGIN_URL = '#{platforms_params[:root_url]}/auth/login/'",
          "LOGOUT_URL = '#{platforms_params[:root_url]}/auth/logout/'",
          "LOGIN_REDIRECT_URL = '#{platforms_params[:root_url]}'",
          'COMPRESS_OFFLINE = True',
          "FILE_UPLOAD_TEMP_DIR = '/tmp'"
        ])
      end
    end

    context 'with overridden parameters' do
      before do
        params.merge!({
          :cache_server_ip         => '10.0.0.1',
          :keystone_default_role   => 'SwiftOperator',
          :keystone_url            => 'https://keystone.example.com:4682',
          :openstack_endpoint_type => 'internalURL',
          :secondary_endpoint_type => 'ANY-VALUE',
          :django_debug            => true,
          :api_result_limit        => 4682,
          :compress_offline        => 'False',
          :hypervisor_options      => {'can_set_mount_point' => false, 'can_set_password' => true },
          :neutron_options         => {'enable_lb' => true, 'enable_firewall' => true, 'enable_quotas' => false, 'enable_security_group' => false, 'enable_vpn' => true, 'profile_support' => 'cisco' },
          :file_upload_temp_dir    => '/var/spool/horizon'
        })
      end

      it 'generates local_settings.py' do
        verify_contents(subject, platforms_params[:config_file], [
          'DEBUG = True',
          "ALLOWED_HOSTS = ['*', ]",
          "SECRET_KEY = 'elj1IWiLoWHgcyYxFVLj7cM5rGOOxWl0'",
          'OPENSTACK_KEYSTONE_URL = "https://keystone.example.com:4682"',
          'OPENSTACK_KEYSTONE_DEFAULT_ROLE = "SwiftOperator"',
          "    'can_set_mount_point': False,",
          "    'can_set_password': True,",
          "    'enable_lb': True,",
          "    'enable_firewall': True,",
          "    'enable_quotas': False,",
          "    'enable_security_group': False,",
          "    'enable_vpn': True,",
          "    'profile_support': 'cisco',",
          'OPENSTACK_ENDPOINT_TYPE = "internalURL"',
          'SECONDARY_ENDPOINT_TYPE = "ANY-VALUE"',
          'API_RESULT_LIMIT = 4682',
          'COMPRESS_OFFLINE = False',
          "FILE_UPLOAD_TEMP_DIR = '/var/spool/horizon'"
        ])
      end

      it { should contain_exec('refresh_horizon_django_cache') }
    end

    context 'with deprecated parameters' do
      before do
        params.merge!({
          :keystone_host       => 'keystone.example.com',
          :keystone_port       => 4682,
          :keystone_scheme     => 'https',
          :can_set_mount_point => true,
        })
      end

      it 'generates local_settings.py' do
        verify_contents(subject, platforms_params[:config_file], [
          'OPENSTACK_KEYSTONE_URL = "https://keystone.example.com:4682/v2.0"',
          "    'can_set_mount_point': True,"
        ])
      end
    end

    context 'with vhost_extra_params' do
      before do
        params.merge!({
          :vhost_extra_params   => { 'add_listen' => false },
        })
      end

      it 'configures apache' do
        should contain_class('horizon::wsgi::apache').with({
          :extra_params => { 'add_listen' => false },
        })
      end
    end


    context 'with ssl enabled' do
      before do
        params.merge!({
          :listen_ssl   => true,
          :servername   => 'some.host.tld',
          :horizon_cert => '/etc/pki/tls/certs/httpd.crt',
          :horizon_key  => '/etc/pki/tls/private/httpd.key',
          :horizon_ca   => '/etc/pki/tls/certs/ca.crt',
        })
      end

      it 'configures apache' do
        should contain_class('horizon::wsgi::apache').with({
          :bind_address => nil,
          :listen_ssl   => true,
          :horizon_cert => '/etc/pki/tls/certs/httpd.crt',
          :horizon_key  => '/etc/pki/tls/private/httpd.key',
          :horizon_ca   => '/etc/pki/tls/certs/ca.crt',
        })
      end
    end

    context 'without apache' do
      before do
        params.merge!({ :configure_apache => false })
      end

      it 'does not configure apache' do
        should_not contain_class('horizon::wsgi::apache')
      end
    end

    context 'with available_regions parameter' do
      before do
        params.merge!({
          :available_regions => [
            ['http://region-1.example.com:5000/v2.0', 'Region-1'],
            ['http://region-2.example.com:5000/v2.0', 'Region-2']
          ]
        })
      end

      it 'AVAILABLE_REGIONS is configured' do
        verify_contents(subject, platforms_params[:config_file], [
          "AVAILABLE_REGIONS = [",
          "    ('http://region-1.example.com:5000/v2.0', 'Region-1'),",
          "    ('http://region-2.example.com:5000/v2.0', 'Region-2'),",
          "]"
        ])
      end
    end

    context 'with overriding local_settings_template' do
      before do
        params.merge!({
          :django_debug            => 'True',
          :help_url                => 'https://docs.openstack.org',
          :local_settings_template => fixtures_path + '/override_local_settings.py.erb'
        })
      end

      it 'uses the custom local_settings.py template' do
        verify_contents(subject, platforms_params[:config_file], [
          '# Custom local_settings.py',
          'DEBUG = True',
          "HORIZON_CONFIG = {",
          "    'dashboards': ('project', 'admin', 'settings',),",
          "    'default_dashboard': 'project',",
          "    'user_home': 'openstack_dashboard.views.get_user_home',",
          "    'ajax_queue_limit': 10,",
          "    'auto_fade_alerts': {",
          "        'delay': 3000,",
          "        'fade_duration': 1500,",
          "        'types': ['alert-success', 'alert-info']",
          "    },",
          "    'help_url': \"https://docs.openstack.org\",",
          "    'exceptions': {'recoverable': exceptions.RECOVERABLE,",
          "                   'not_found': exceptions.NOT_FOUND,",
          "                   'unauthorized': exceptions.UNAUTHORIZED},",
          "}",
        ])
      end
    end
  end

  context 'on RedHat platforms' do
    before do
      facts.merge!({
        :osfamily               => 'RedHat',
        :operatingsystemrelease => '6.0'
      })
    end

    let :platforms_params do
      { :config_file       => '/etc/openstack-dashboard/local_settings',
        :package_name      => 'openstack-dashboard',
        :root_url          => '/dashboard' }
    end

    it_behaves_like 'horizon'
  end

  context 'on Debian platforms' do
    before do
      facts.merge!({
        :osfamily               => 'Debian',
        :operatingsystemrelease => '6.0'
      })
    end

    let :platforms_params do
      { :config_file       => '/etc/openstack-dashboard/local_settings.py',
        :package_name      => 'openstack-dashboard-apache',
        :root_url          => '/horizon' }
    end

    it_behaves_like 'horizon'
  end
end
