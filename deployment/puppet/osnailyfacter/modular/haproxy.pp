
class { 'cluster::haproxy':
        haproxy_maxconn    => '16000',
        haproxy_bufsize    => '32768',
        primary_controller => hiera('primary_controller'),
      }
