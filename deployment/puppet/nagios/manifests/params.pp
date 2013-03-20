class nagios::params {

  $services_list = {
    'nova-compute' => 'check_nrpe_1arg!check_nova_compute',
    'nova-network' => 'check_nrpe_1arg!check_nova_network',
    'libvirt' => 'check_nrpe_1arg!check_libvirt',
    'swift-proxy' => 'check_nrpe_1arg!check_swift_proxy',
    'swift-account' => 'check_nrpe_1arg!check_swift_account',
    'swift-container' => 'check_nrpe_1arg!check_swift_container',
    'swift-object' => 'check_nrpe_1arg!check_swift_object',
    'swift-ring' => 'check_nrpe_1arg!check_swift_ring',
    'keystone' => 'check_http_api!5000',
    'nova-novncproxy' => 'check_nrpe_1arg!check_nova_novncproxy',
    'nova-scheduler' => 'check_nrpe_1arg!check_nova_scheduler',
    'nova-consoleauth' => 'check_nrpe_1arg!check_nova_consoleauth',
    'nova-cert' => 'check_nrpe_1arg!check_nova_cert',
    'cinder-scheduler' => 'check_nrpe_1arg!check_cinder_scheduler',
    'cinder-volume' => 'check_nrpe_1arg!check_cinder_volume',
    'haproxy' => 'check_nrpe_1arg!check_haproxy',
    'memcached' => 'check_nrpe_1arg!check_memcached',
    'nova-api' => 'check_http_api!8774',
    'cinder-api' => 'check_http_api!8776',
    'glance-api' => 'check_http_api!9292',
    'glance-registry' => 'check_nrpe_1arg!check_glance_registry',
    'horizon' => 'check_http_api!80',
    'rabbitmq' => 'check_rabbitmq',
    'mysql' => 'check_galera_mysql',
    'apt' => 'nrpe_check_apt',
    'kernel' => 'nrpe_check_kernel',
    'libs' => 'nrpe_check_libs',
    'load' => 'nrpe_check_load!5.0!4.0!3.0!10.0!6.0!4.0',
    'procs' => 'nrpe_check_procs!250!400',
    'zombie' => 'nrpe_check_procs_zombie!5!10',
    'swap' => 'nrpe_check_swap!20%!10%',
    'user' => 'nrpe_check_users!5!10',
    'host-alive' => 'check-host-alive',
  }

  case $::osfamily {
    'RedHat': {
      $nagios3pkg = [
        'nagios', 'nagios-plugins-nrpe',
         ]
      $nrpepkg = [
        'binutils',
        'openssl',
        'nrpe',
        'nagios-plugins-nrpe',
        'nagios-plugins-by_ssh', 'nagios-plugins-cluster', 'nagios-plugins-dhcp',
        'nagios-plugins-dig', 'nagios-plugins-disk', 'nagios-plugins-dns',
        'nagios-plugins-dummy', 'nagios-plugins-flexlm', 'nagios-plugins-http',
        'nagios-plugins-icmp', 'nagios-plugins-ide_smart',
        'nagios-plugins-ircd', 'nagios-plugins-mysql',
        'nagios-plugins-nt', 'nagios-plugins-ntp', 'nagios-plugins-ntp-perl',
        'nagios-plugins-nwstat', 'nagios-plugins-overcr', 'nagios-plugins-ping',
        'nagios-plugins-procs', 'nagios-plugins-real',
        'nagios-plugins-rpc', 'nagios-plugins-sensors', 'nagios-plugins-ssh',
        'nagios-plugins-swap', 'nagios-plugins-tcp', 'nagios-plugins-time',
        'nagios-plugins-users',  ]
      $nagios_os_name = 'nagios'
      $masterdir = $nagios_os_name
      $masterservice = $nagios_os_name
      $htpasswd_file  = 'passwd'
      $libdir = '/usr/lib64'
      $nrpeservice = 'nrpe'
      $distro = inline_template("<%= scope.lookupvar('::osfamily').downcase -%>")
      $icon_image = "${distro}.png"
      $statusmap_image  = "${distro}.gd2"
      $nginx_pkgs = ['nginx', 'spawn-fcgi', 'fcgiwrap']
      $nginx_sites_enabled = '/etc/nginx/conf.d/nagios.conf'
      $apache_service = 'httpd'
      $apache_user = 'apache'
      $nginx_service = 'nginx'
      $php_service = 'spawn-fcgi-php'
      $fcgiwrap_service = 'spawn-fcgi'
    }
    'Debian': {
      $nagios3pkg = [
        'nagios3',
        'nagios-nrpe-plugin' ]
      $nrpepkg = [
        'binutils',
        'libnagios-plugin-perl',
        'nagios-nrpe-server',
        'nagios-plugins-basic',
        'nagios-plugins-standard']
      $nagios_os_name = 'nagios3'
      $masterdir = $nagios_os_name
      $masterservice = $nagios_os_name
      $htpasswd_file  = 'htpasswd.users'
      $libdir    = '/usr/lib'
      $nrpeservice = 'nagios-nrpe-server'
      $distro = inline_template("<%= scope.lookupvar('::lsbdistid').downcase -%>")
      $icon_image = "base/${distro}.png"
      $statusmap_image = "base/${distro}.gd2"
      $nginx_pkgs = ['nginx','fcgiwrap','php5-fpm']
      $apache_service  = 'apache2'
      $apache_user = 'www-data'
      $nginx_service = 'nginx'
      $nginx_sites_enabled = '/etc/nginx/sites-enabled/nagios3'
      $php_service = 'php5-fpm'
      $fcgiwrap_service = 'fcgiwrap'
    }
  }
}
