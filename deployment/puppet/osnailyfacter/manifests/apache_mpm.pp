# Configure apache MPM
class osnailyfacter::apache_mpm inherits ::osnailyfacter::apache {

  # Performance optimization for Apache mpm
  if ($::memorysize_mb + 0) < 4100 {
    $maxclients = 100
  } else {
    $maxclients = inline_template('<%= Integer(@memorysize_mb.to_i / 10) %>')
  }

  if ($::processorcount + 0) <= 2 {
    $startservers = 2
  } else {
    $startservers = $::os_workers
  }

  $maxrequestsperchild = 0
  $threadsperchild     = 25
  $minsparethreads     = 25
  $serverlimit         = inline_template('<%= Integer(@maxclients.to_i / @threadsperchild.to_i) %>')
  $maxsparethreads     = inline_template('<%= Integer(@maxclients.to_i / 2) %>')

  # Define apache mpm
  if $::osfamily == 'RedHat' {
    $mpm_module = 'event'
  } else {
    $mpm_module = 'worker'

    file { [
      "$::apache::params::mod_enable_dir/mpm_event.load",
      "$::apache::params::mod_enable_dir/mpm_event.conf"
    ]:
      ensure => 'absent',
      require => Package['httpd'],
      notify  => Service['httpd'],
    }

  }

  class { "::apache::mod::$mpm_module":
    startservers        => $startservers,
    maxclients          => $maxclients,
    minsparethreads     => $minsparethreads,
    maxsparethreads     => $maxsparethreads,
    threadsperchild     => $threadsperchild,
    maxrequestsperchild => $maxrequestsperchild,
    serverlimit         => $serverlimit,
  }
}
