# PRIVATE CLASS: do not call directly
class mongodb::server::config {
  $ensure          = $mongodb::server::ensure
  $user            = $mongodb::server::user
  $group           = $mongodb::server::group
  $config          = $mongodb::server::config

  $dbpath          = $mongodb::server::dbpath
  $pidfilepath     = $mongodb::server::pidfilepath
  $logpath         = $mongodb::server::logpath
  $logappend       = $mongodb::server::logappend
  $fork            = $mongodb::server::fork
  $port            = $mongodb::server::port
  $journal         = $mongodb::server::journal
  $nojournal       = $mongodb::server::nojournal
  $smallfiles      = $mongodb::server::smallfiles
  $cpu             = $mongodb::server::cpu
  $auth            = $mongodb::server::auth
  $noath           = $mongodb::server::noauth
  $verbose         = $mongodb::server::verbose
  $verbositylevel  = $mongodb::server::verbositylevel
  $objcheck        = $mongodb::server::objcheck
  $quota           = $mongodb::server::quota
  $quotafiles      = $mongodb::server::quotafiles
  $diaglog         = $mongodb::server::diaglog
  $oplog_size      = $mongodb::server::oplog_size
  $nohints         = $mongodb::server::nohints
  $nohttpinterface = $mongodb::server::nohttpinterface
  $noscripting     = $mongodb::server::noscripting
  $notablescan     = $mongodb::server::notablescan
  $noprealloc      = $mongodb::server::noprealloc
  $nssize          = $mongodb::server::nssize
  $mms_token       = $mongodb::server::mms_token
  $mms_name        = $mongodb::server::mms_name
  $mms_interval    = $mongodb::server::mms_interval
  $master          = $mongodb::server::master
  $slave           = $mongodb::server::slave
  $only            = $mongodb::server::only
  $source          = $mongodb::server::source
  $configsvr       = $mongodb::server::configsvr
  $shardsvr        = $mongodb::server::shardsvr
  $replset         = $mongodb::server::replset
  $rest            = $mongodb::server::rest
  $quiet           = $mongodb::server::quiet
  $slowms          = $mongodb::server::slowms
  $keyfile         = $mongodb::server::keyfile
  $key             = $mongodb::server::key
  $ipv6            = $mongodb::server::ipv6
  $bind_ip         = $mongodb::server::bind_ip
  $directoryperdb  = $mongodb::server::directoryperdb
  $profile         = $mongodb::server::profile
  $set_parameter   = $mongodb::server::set_parameter
  $syslog          = $mongodb::server::syslog
  $ssl             = $mongodb::server::ssl
  $ssl_key         = $mongodb::server::ssl_key
  $ssl_ca          = $mongodb::server::ssl_ca

  if $mongodb::server::cfg_content {
    $cfg_content = $mongodb::server::cfg_content
  } else {
    $cfg_content = template('mongodb/mongodb.conf.erb')
  }

  File {
    owner => $user,
    group => $group,
  }

  if ($logpath and $syslog) { fail('You cannot use syslog with logpath')}

  if ($ensure == 'present' or $ensure == true) {

    # Exists for future compatibility and clarity.
    if $auth {
      $noauth = false
    }
    else {
      $noauth = true
    }
    if $keyfile and $key {
      validate_string($key)
      validate_re($key,'.{6}')
      file { $keyfile:
        content => $key,
        owner   => $user,
        group   => $group,
        mode    => '0400',
      }
    }

    file { $config:
      content => $cfg_content,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      notify  => Class['mongodb::server::service']
    }

    file { $dbpath:
      ensure  => directory,
      mode    => '0755',
      owner   => $user,
      group   => $group,
      require => File[$config]
    }
  } else {
    file { $dbpath:
      ensure => absent,
      force  => true,
      backup => false,
    }
    file { $config:
      ensure => absent
    }
  }
}
