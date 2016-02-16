# == Class: cobbler::apache
#
#  Configure apache and listen ports.
#
class cobbler::apache {
  class { '::apache':
    server_signature => 'Off',
  }

  apache::vhost { 'nailgun non-ssl':
    servername      => 'nailgun',
    docroot         => '/var/www/html',
    custom_fragment => 'RewriteEngine on
      RewriteCond %{HTTPS} off
      RewriteRule ^/$ https://%{HTTP_HOST}:8443%{REQUEST_URI} [R=301,L]
      RewriteCond %{HTTPS} off
      RewriteCond %{REQUEST_URI} !^/(cblr|cobbler)
      RewriteRule (.*) http://%{HTTP_HOST}:8000%{REQUEST_URI} [R=301,L]',
    aliases        => [
      { alias => '/cobbler/boot',
        path  => '/var/lib/tftpboot',
      },
    ],
    directories    => [
      { path    => '/var/lib/tftpboot',
        options => ['Indexes', 'FollowSymLinks'],
      },
    ],
  }

  apache::vhost { 'nailgun ssl':
    servername      => 'nailgun',
    port            => 443,
    docroot         => '/var/www/html',
    ssl             => true,
    ssl_cert        => "/var/lib/fuel/keys/master/cobbler/cobbler.crt",
    ssl_key         => "/var/lib/fuel/keys/master/cobbler/cobbler.key",
    custom_fragment => 'RewriteEngine on
      RewriteCond %{HTTPS} off
      RewriteRule ^/$ https://%{HTTP_HOST}:8443%{REQUEST_URI} [R=301,L]'
  }
}
