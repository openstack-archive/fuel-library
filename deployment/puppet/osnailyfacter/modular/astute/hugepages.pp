notice('MODULAR: hugepages.pp')

# @params Hash { count: <Integer>, numa_id: <Id>, size: <Kbytes> }
define allocate_hugepages { # lint:ignore:autoloader_layout
  validate_hash($title)

  # lint:ignore:80chars
  file { "/sys/devices/system/node/node${title['numa_id']}/hugepages/hugepages-${title['size']}KB/nr_hugepages":
    ensure  => file,
    content => "${title['count']}", # lint:ignore:only_variable_string
  }
  # lint:endignore
}

$hugepages = hiera_array('hugepages', false)

if $hugepages {
  validate_array($hugepages)
  allocate_hugepages { $hugepages: }
}
