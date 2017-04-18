# == Class: cobbler::apache
#
#  Configure apache and listen ports.
#
class cobbler::apache {
  file { ['/etc/httpd/', '/etc/httpd/conf.ports.d/']: ensure  => directory }
  ->
  class { '::apache':
    server_signature => 'Off',
    trace_enable     => 'Off',
    purge_configs    => false,
    purge_vhost_dir  => false,
    default_vhost    => false,
    ports_file       => '/etc/httpd/conf.ports.d/cobbler.conf',
    conf_template    => 'fuel/httpd.conf.erb',
  }

  apache::vhost { 'cobbler non-ssl':
    servername  => '_default_',
    port        => 80,
    docroot     => '/var/www/html',
    rewrites    => [
      {
        comment      => 'Redirect root path to SSL Nailgun',
        rewrite_cond => ['%{HTTPS} off'],
        rewrite_rule => ['^/$ https://%{HTTP_HOST}:8443%{REQUEST_URI} [R=301,L]']
      },
      {
        comment      => 'Redirect other non-cobbler path to Nailgun',
        rewrite_cond => ['%{HTTPS} off', '%{REQUEST_URI} !^/(cblr|cobbler)'],
        rewrite_rule => ['(.*) http://%{HTTP_HOST}:8000%{REQUEST_URI} [R=301,L]']
      },
    ],
    aliases     => [
      {
        alias => '/cobbler/boot',
        path  => '/var/lib/tftpboot',
      },
    ],
    directories => [
      {
        path    => '/var/lib/tftpboot',
        options => ['Indexes', 'FollowSymLinks'],
      },
    ],
  }

  apache::vhost { 'cobbler ssl':
    servername      => '_default_',
    port            => 443,
    docroot         => '/var/www/html',
    ssl             => true,
    ssl_cert        => '/var/lib/fuel/keys/master/cobbler/cobbler.crt',
    ssl_key         => '/var/lib/fuel/keys/master/cobbler/cobbler.key',
    rewrites        => [
      {
        comment      => 'Redirect root path to SSL Nailgun',
        rewrite_rule => ['^/$ https://%{HTTP_HOST}:8443%{REQUEST_URI} [R=301,L]']
      },
    ],
    custom_fragment => '
      CustomLog logs/ssl_request_log "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"',
    ssl_cipher      => 'ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS',
    setenvif        => ['User-Agent ".*MSIE.*" nokeepalive ssl-unclean-shutdown downgrade-1.0 force-response-1.0'],
  }
}
