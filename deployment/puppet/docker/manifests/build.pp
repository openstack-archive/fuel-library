# == Class: docker::build
#
# Build and run docker containers
#
# === Parameters
#
# [*containers*]
#   (required) Array. This is an array of container names. Order does matter.
#

class docker::build (
  $containers = ['postgres', 'rabbitmq', 'keystone', 'rsync', 'astute', 'rsyslog',
                 'nailgun', 'ostf', 'nginx', 'cobbler', 'mcollective'],
) {

  define docker::build::containers ($container = $title) {

    $cnt_index = inline_template("<%= @containers.index(@container) %>")
    $cnt_last  = inline_template("<%= @containers[-1]%>")

    exec { "container${cnt_index}":
      command   => "dockerctl --debug build ${container}",
      path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      timeout   => 7200,
      logoutput => true,
      unless    => "docker ps -a | egrep -q \"fuel-.*${container}\"",
    }

    if $cnt_index != 0 {
      $cnt_before = inline_template("<%= @containers.index(@container)-1 %>")
      Exec["container${cnt_before}"] -> Exec["container${cnt_index}"]
    }
  }

  # This creates a new Exec['containter<N>'] resources with dependeny:
  # Exec['container0']->Exec['containter1']->Exec['containter<N>']
  docker::build::containers { $containers: }

}
