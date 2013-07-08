#
class openstack::logrotate (
    $rotation       = 'daily',
    $keep           = '7',
    $limitsize      = '300M',
) {
  validate_re($rotation, 'daily|weekly|monthly|yearly')

  file { "/etc/logrotate.d/10-fuel.conf":
    owner => 'root',
    group => 'root',
    mode  => '0644',
    content => template("openstack/10-fuel.conf.erb"),    
  }

# Due to bug existing, logrotate always returns 0. Use grep for detect errors:
# would return 1 (considered as normal result), if logrotate returns no errors, return 0, if any. 
  exec {'logrotate_check':
    path    => ["/usr/bin", "/usr/sbin", "/sbin", "/bin"],
    command => "logrotate /etc/logrotate.d/10-fuel.conf >& /tmp/logrotate && grep -q error /tmp/logrotate",
    returns => 1,
    require => File['/etc/logrotate.d/10-fuel.conf'],
  }
}
