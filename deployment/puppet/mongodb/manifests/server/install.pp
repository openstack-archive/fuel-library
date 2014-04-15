# PRIVATE CLASS: do not call directly
class mongodb::server::install {
  $package_ensure = $mongodb::server::package_ensure
  $package_name   = $mongodb::server::package_name

  case $package_ensure {
    true:     {
      $_package_ensure = 'present'
      $file_ensure     = 'directory'
    }
    false:    {
      $_package_ensure = 'purged'
      $file_ensure     = 'absent'
    }
    'absent': {
      $_package_ensure = 'purged'
      $file_ensure     = 'absent'
    }
    default:  {
      $_package_ensure = $package_ensure
      $file_ensure     = 'present'
    }
  }

  package { 'mongodb_server':
    ensure => $_package_ensure,
    name   => $package_name,
    tag    => 'mongodb',
  }
}
