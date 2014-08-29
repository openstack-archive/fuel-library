class osnailyfacter::patching_classes ()
{
  case $::osfamily {
    'Debian': {
      $packages=[
        'python-oslo.messaging',
        'python-pastedeploy',
        'python-routes',
        'python-sqlalchemy-ext',
        'python-sqlalchemy',
        'python-testtools'
      ]
    }
    'RedHat': {
      $packages=[
        'python-oslo-messaging',
        'python-paste-deploy',
        'python-routes',
        'python-six',
        'python-sqlalchemy'
      ]
    }
  }
  notify{'Installing explicit OpenStack dependencies':} ->
  package {$packages: ensure => latest }
}


