class { '::openstack_tasks::swift::proxy_storage' :}

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

warning('osnailyfacter/modular/./swift/proxy_storage.pp is deprecated in mitaka and will be removed in newton. Please use openstack_tasks/examples/./swift/proxy_storage.pp')
