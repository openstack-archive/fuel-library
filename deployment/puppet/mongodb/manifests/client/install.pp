# PRIVATE CLASS: do not call directly
class mongodb::client::install {
  $package_ensure = $mongodb::client::package_ensure
  $package_name   = $mongodb::client::package_name

  case $package_ensure {
    true:     {
      $_package_ensure = 'present'
    }
    false:    {
      $_package_ensure = 'purged'
    }
    'absent': {
      $_package_ensure = 'purged'
    }
    default:  {
      $_package_ensure = $package_ensure
    }
  }

  package { 'mongodb_client':
    ensure => $_package_ensure,
    name   => $package_name,
    tag    => 'mongodb_client',
  }
}
