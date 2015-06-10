# puppet-memcached [![Build Status](https://secure.travis-ci.org/saz/puppet-memcached.png)](http://travis-ci.org/saz/puppet-memcached)

Manage memcached via Puppet

## Show some love
If you find this module useful, send some bitcoins to 1Na3YFUmdxKxJLiuRXQYJU2kiNqA3KY2j9

## How to use

### Use roughly 90% of memory

```ruby
    class { 'memcached': }
```

### Set a fixed memory limit in MB

```ruby
    class { 'memcached':
      max_memory => 2048
    }
```

### Use 12% of available memory

```ruby
    class { 'memcached':
      max_memory => '12%'
    }
```

### Other class parameters

* $package_ensure = 'present'
* $logfile = '/var/log/memcached.log'
* $pidfile = '/var/run/memcached.pid' (Debian family only, set to false to disable pidfile)
* $max_memory = false
* $item_size = false
* $lock_memory = false (WARNING: good if used intelligently, google for -k key)
* $listen_ip = '0.0.0.0'
* $tcp_port = 11211
* $udp_port = 11211
* $manage_firewall = false
* $user = '' (OS specific setting, see params.pp)
* $max_connections = 8192
* $verbosity = undef
* $unix_socket = undef
* $install_dev = false (TRUE if 'libmemcached-dev' package should be installed)
* $processorcount = $::processorcount
* $service_restart = true (restart service after configuration changes, false to prevent restarts)
* $use_sasl = false (start memcached with SASL support)
* $large_mem_pages = false (try to use large memory pages)
