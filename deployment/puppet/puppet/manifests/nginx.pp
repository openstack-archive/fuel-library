class puppetmaster::nginx(
  $puppet_master_hostname,
  $cacert = $::cacert,
  $cakey = $::cakey,
  $localcacert = $::localcacert,
  $cacrl = $::cacrl,
  ) {

  package { "nginx": }

  file { "/etc/nginx/conf.d/puppet.conf":
    content => template("puppetmaster/nginx_puppet.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => Package["nginx"],
    notify => Service["nginx"],
  }
    
  service { "nginx":
    enable => true,
    ensure => "running",
    require => Package["nginx"],
  }

}
