# == Define: osnailyfacter::allocate_hugepages
#
# Allocate defined hugepages.
#
# === parameters:
# [*title*]
#   Hash { count: <Integer>, numa_id: <Id>, size: <Kbytes> }
#
# === Example
# $hugepages = { count => 512, numa_id => 0, size => 2048 }
# osnailyfacter::allocate_hugepages { $hugepages: }
#
define osnailyfacter::allocate_hugepages {
  validate_hash($title)

  # lint:ignore:80chars
  file { "/sys/devices/system/node/node${title['numa_id']}/hugepages/hugepages-${title['size']}kB/nr_hugepages":
    ensure  => file,
    content => "${title['count']}", # lint:ignore:only_variable_string
  }
  # lint:endignore
}
