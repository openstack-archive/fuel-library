# this is all of the python deps for openstack
# I should probably split these up to be more 
# compartamelalzed
class python {
  package { 
    [
    'python-gflags',
    'python-carrot',
    'python-eventlet',
    'python-ipy',
    'python-sqlalchemy',
    'python-mysqldb',
    'python-webob',
    'python-mox',
    'python-routes',
    'python-daemon',
    'python-boto',
    'python-m2crypto',
    'python-cheetah',
    'python-netaddr',
    'python-pastedeploy',
    'python-migrate',
    'python-tempita', 
    'python-twisted',
    'python-setuptools',
    'python-nose',
    'python-dev',
    'python-pip',
    'python-sphinx',
    'python-argparse'
    ]:
    ensure => present,
  }
  package { ['pep8', 'xenapi']:
    provider => 'pip',
    ensure => present,
    require => Package['python-pip'],
  }
}
