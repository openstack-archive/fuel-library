require 'spec_helper'

describe 'cobbler::apache' do

  shared_examples_for 'cobbler configuration' do

    context 'with default params' do

      it 'configures with the default params' do
        should contain_apache_vhost('cobbler non-ssl').with(
          :servername      => '_default_',
          :docroot         => '/var/www/html',
          :custom_fragment => 'RewriteEngine on
      RewriteCond %{HTTPS} off
      RewriteRule ^/$ https://%{HTTP_HOST}:8443%{REQUEST_URI} [R=301,L]
      RewriteCond %{HTTPS} off
      RewriteCond %{REQUEST_URI} !^/(cblr|cobbler)
      RewriteRule (.*) http://%{HTTP_HOST}:8000%{REQUEST_URI} [R=301,L]',
          :aliases         => [
            { :alias => '/cobbler/boot',
              :path  => '/var/lib/tftpboot',
            },
          ],
          :directories     => [
            { :path    => '/var/lib/tftpboot',
              :options => ['Indexes', 'FollowSymLinks'],
            },
          ],
        )
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      @default_facts.merge({ :osfamily => 'Debian',
        :operatingsystem => 'Debian',
      })
    end

    it_configures 'cobbler configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      @default_facts.merge({ :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
      })
    end

    it_configures 'cobbler configuration'
  end

end

