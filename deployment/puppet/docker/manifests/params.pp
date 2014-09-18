class docker::params
{
  #Default weights
  $default_cpu_weight = 1
  $default_memory_limit = inline_template("<%= (${::memorysize_mb} / 20 + 0).floor %>m")

  #Container specific weights
  $cpu_weights['astute']      = 2
  $cpu_weights['cobbler']     = 2
  $cpu_weights['mcollective'] = 4
  $cpu_weights['nailgun']     = 4

  $memory_limits['astuter']     = inline_template("<%= (${::memorysize_mb} / 8 + 0).floor %>m")
  $memory_limits['cobbler']     = inline_template("<%= (${::memorysize_mb} / 8 + 0).floor %>m")
  $memory_limits['mcollective'] = inline_template("<%= (${::memorysize_mb} / 5 + 0).floor %>m")
  $memory_limits['nailgun']     = inline_template("<%= (${::memorysize_mb} / 5 + 0).floor %>m")
}
