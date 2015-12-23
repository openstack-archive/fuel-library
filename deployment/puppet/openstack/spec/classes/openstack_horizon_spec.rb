require 'spec_helper'

describe 'openstack::horizon' do

  let(:upload_dir) { '/var/lib/horizon/tmp' }

  let(:default_params) { {
    :debug => false,
    :fqdn           => 'some.host.tld'
  } }

  let(:params) { {
    :secret_key => 'very_secret_key',
    :file_upload_max_size => '10737418235',
    :file_upload_temp_dir => upload_dir
  } }

  let :facts do
    { :concat_basedir => '/var/lib/puppet/concat',
      :fqdn           => 'some.host.tld'
    }
  end

  shared_examples_for 'horizon configuration' do
    let :p do
      default_params.merge(params)
    end


    context 'with a default config' do
      it 'contains openstack::horizon' do
        should contain_class('openstack::horizon')
       # .with(
       #   :file_upload_temp_dir => '/var/lib/horizon/tmp'
       # )
      end

      it 'contains horizon::wsgi::apache' do
        if facts[:osfamily] == 'Debian'
          custom_fragment = "\n  <Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>\n    Order allow,deny\n    Allow from all\n  </Directory>\n\n  LimitRequestBody 10737418235\n\n"
        elsif facts[:osfamily] == 'RedHat'
          custom_fragment = "\n  <Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>\n    <IfModule mod_deflate.c>\n      SetOutputFilter DEFLATE\n      <IfModule mod_headers.c>\n        # Make sure proxies don't deliver the wrong content\n        Header append Vary User-Agent env=!dont-vary\n      </IfModule>\n    </IfModule>\n\n    Order allow,deny\n    Allow from all\n  </Directory>\n\n  <Directory /usr/share/openstack-dashboard/static>\n    <IfModule mod_expires.c>\n      ExpiresActive On\n      ExpiresDefault \"access 6 month\"\n    </IfModule>\n    <IfModule mod_deflate.c>\n      SetOutputFilter DEFLATE\n    </IfModule>\n\n    Order allow,deny\n    Allow from all\n  </Directory>\n\n  LimitRequestBody 10737418235\n\n"
        end

        should contain_class('horizon::wsgi::apache').with(
          :extra_params => {
            'add_listen'        => false,
            'ip_based'          => true,
            'custom_fragment'   => custom_fragment,
            'default_vhost'     => true,
            'headers'           => ["set X-XSS-Protection \"1; mode=block\"", "set X-Content-Type-Options nosniff", "always append X-Frame-Options SAMEORIGIN"],
            'options'           => '-Indexes',
            'setenvif'          => 'X-Forwarded-Proto https HTTPS=1',
            'access_log_format' => '%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"'
          }
        )
      end
    end
  end

  context 'on Debian platforms' do
    before do
      facts.merge!(
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :operatingsystemrelease => '8',
        :hostname => 'hostname.example.com',
        :physicalprocessorcount => 2,
        :memorysize_mb => 1024,
        :openstack_version => {'nova' => 'present' },
      })
    end

    it_configures 'horizon configuration'
  end

  context 'on RedHat platforms' do
    before do
      facts.merge!(
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :operatingsystemrelease => '6.6',
        :hostname => 'hostname.example.com',
        :physicalprocessorcount => 2,
        :memorysize_mb => 1024,
        :openstack_version => {'nova' => 'present' },
      })
    end

    it_configures 'horizon configuration'
  end

end
