notice("MODULAR: apt_proxy.pp")

$master_ip      = hiera('master_ip', undef)
$http_proxy_url = hiera('http_proxy_url', undef)
$apt_config_dir = '/etc/apt/apt.conf.d/'

if $::osfamily == 'Debian' and $http_proxy_url and $master_ip {
  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  file { 'apt_config_dir' :
    ensure => 'directory',
    path   => $apt_config_dir,
  }

  file { 'apt_proxy_config' :
    ensure  => 'present',
    path    => "${apt_config_dir}/90proxy",
    content => inline_template("Acquire::Http::Proxy \"<%= @http_proxy_url %>\";\nAcquire::Http::Proxy::<%= @master_ip %> DIRECT;\n"),
  }
}
