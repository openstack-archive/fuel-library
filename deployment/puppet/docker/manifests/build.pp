# == Define: docker::build
#
# Build and run docker containers
#
# === Parameters
#
# [*title*]
#   (required) String. The name of container for the new Exec resources.
#
# [*containers*]
#   (required) Array. This is an array of container names. Order does matter.
#

define docker::build ($container  = $title) {

  $cnt_index = inline_template("<%= @containers.index(@container) %>")
  $name_last = inline_template("<%= @containers[-1]%>")

  exec { "container${cnt_index}build":
    command   => "dockerctl --debug build ${container}",
    path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    timeout   => 7200,
    logoutput => true,
    loglevel  => 'debug',
    unless    => "docker ps -a | egrep -q \"fuel-.*${container}\"",
  }

  exec { "container${cnt_index}check":
    command   => "dockerctl --debug check ${container}",
    path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    timeout   => 7200,
    logoutput => true,
    loglevel  => 'debug',
    onlyif    => "docker ps -a | egrep -q \"fuel-.*${container}\"",
  }

  if $cnt_index != 0 {
    $cnt_before = inline_template("<%= @containers.index(@container)-1 %>")
    Exec["container${cnt_before}build"] -> Exec["container${cnt_before}check"] ->
    Exec["container${cnt_index}build"] -> Exec["container${cnt_index}check"]
  } else {
    Anchor<| title == 'docker-build-start' |> -> Exec["container0build"]
  }

  if $container == $name_last {
    Exec["container${cnt_index}check"] -> Anchor<| title == 'docker-build-end' |>
  }

}
