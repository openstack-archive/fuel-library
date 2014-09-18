class docker::params
{
  #Default weights
  $default_cpu_weight = 1024
  $default_memory_limit = inline_template("<%= (${::memorysize_mb} / 20 + 0).floor %>m")

  #Container specific weights
  $cpu_weights = {
    'astute' => 2048,
    'cobbler' => 2048,
    'mcollective' => 4096,
    'nailgun' => 4096,
  }
  $memory_limits = {
    'astute'      => inline_template("<%= (${::memorysize_mb} / 8 + 0).floor %>m"),
    'cobbler'     => inline_template("<%= (${::memorysize_mb} / 8 + 0).floor %>m"),
    'mcollective' => inline_template("<%= (${::memorysize_mb} / 5 + 0).floor %>m"),
    'nailgun'     => inline_template("<%= (${::memorysize_mb} / 5 + 0).floor %>m"),
  }
}
