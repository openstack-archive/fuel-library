# Proxy realization via apache
class osnailyfacter::apache_api_proxy {

  $apache_site_dir = $osnailyfacter::params::apache_site_dir

  # Allow connection to the apache for ostf tests
  firewall {'007 tinyproxy':
    dport   => [ 8888 ],
    source  => $master_ip,
    proto   => 'tcp',
    action  => 'accept',
    require => Class['openstack::firewall'],
  }

  if ($::osfamily == 'Debian') {

    file { '/etc/apache2/sites-available/api_proxy.conf':
      content => template('osnailyfacter/api_proxy.conf.erb'),
      require => Package['dashboard'],
    }->

    file { '/etc/apache2/sites-enabled/api_proxy.conf':
      ensure => 'link',
      target => '/etc/apache2/sites-available/api_proxy.conf',
      notify => Service['httpd'],
    }
  } elsif ($::osfamily == 'RedHat') {

    file { '/etc/httpd/conf.d/api_proxy.conf':
    content => template('osnailyfacter/api_proxy.conf.erb'),
    require => Package['httpd'],
    notify  => Service['httpd'],
    }
  }
}
