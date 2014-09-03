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
        'python-testtools',
        'python-oslo.messaging',
        'python-keystoneclient',
        'python-neutronclient',
        'python-novaclient',
        'python-swiftclient',
        'python-troveclient'
      ]
    }
    'RedHat': {
      $packages=[
        'python-oslo-messaging',
        'python-paste-deploy',
        'python-routes',
        'python-six',
        'python-sqlalchemy',
        'python-keystoneclient',
        'python-neutronclient',
        'python-novaclient',
        'python-swiftclient',
        'python-troveclient'
      ]
    }
  }
  notify{'Installing explicit OpenStack dependencies':} ->
  package {$packages: ensure => latest }
}


