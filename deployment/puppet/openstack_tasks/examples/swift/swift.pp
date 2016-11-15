class { '::openstack_tasks::swift::storage' :}
class { '::openstack_tasks::swift::proxy' :}
class { '::osnailyfacter::upgrade::restart_services' :}
# 'ceilometer' class is being declared inside openstack::ceilometer class
# which is declared inside openstack::controller class in the other task.
# So we need a stub here for dependency from swift::proxy::ceilometer
class ceilometer {}
include ceilometer

# Class[Swift::Proxy::Cache] requires Class[Memcached] if memcache_servers
# contains 127.0.0.1. But we're deploying memcached in another task. So we
# need to add this stub here.
class memcached {}
include memcached

warning('osnailyfacter/modular/swift/swift.pp is deprecated in Mitaka and will be removed in Newton. See new storage.pp and proxy.pp tasks')
class { '::osnailyfacter::override_resources': }
