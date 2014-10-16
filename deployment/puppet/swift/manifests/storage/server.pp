#
# I am not sure if this is the right name
#   - should it be device?
#
#  name - is going to be port
define swift::storage::server(
  $type,
  $storage_local_net_ip,
  $devices                = '/srv/node',
  $owner                  = 'swift',
  $group                  = 'swift',
  $max_connections        = 25,
  $pipeline               = ["${type}-server"],
  $mount_check            = false,
  $user                   = 'swift',
  $workers                = '1',
  $allow_versions         = false,
  $replicator_concurrency = $::processorcount,
  $updater_concurrency    = $::processorcount,
  $reaper_concurrency     = $::processorcount,
  $log_facility           = 'LOG_LOCAL2',
  $log_level              = 'INFO',
  $log_address            = '/dev/log',
  $log_name               = "${type}-server",
  # this parameters needs to be specified after type and name
  $config_file_path       = "${type}-server/${name}.conf"
) {

  # Warn if ${type-server} isn't included in the pipeline
  if is_array($pipeline) {
    if !member($pipeline, "${type}-server") {
      warning("swift storage server ${type} must specify ${type}-server")
    }
  } elsif $pipeline != "${type}-server" {
    warning("swift storage server ${type} must specify ${type}-server")
  }

  include "swift::storage::${type}"
  include concat::setup

  validate_re($name, '^\d+$')
  validate_re($type, '^object|container|account$')
  validate_array($pipeline)
  validate_bool($allow_versions)
  # TODO - validate that name is an integer

  $bind_port = $name

  rsync::server::module { $type:
    path            => $devices,
    lock_file       => "/var/lock/${type}.lock",
    uid             => $owner,
    gid             => $group,
    max_connections => $max_connections,
    read_only       => false,
  }

  concat { "/etc/swift/${config_file_path}":
    owner   => $owner,
    group   => $group,
    notify  => Service["swift-${type}", "swift-${type}-replicator"],
    require => Package['swift'],
    mode    => 640,
  }

  $required_middlewares = split(
    inline_template(
      "<%=
        (@pipeline - ['${type}-server']).collect do |x|
          'Swift::Storage::Filter::' + x.capitalize + '[${type}]'
        end.join(',')
      %>"), ',')

  # you can now add your custom fragments at the user level
  concat::fragment { "swift-${type}-${name}":
    target  => "/etc/swift/${config_file_path}",
    content => template("swift/${type}-server.conf.erb"),
    order   => '00',
    # require classes for each of the elements of the pipeline
    # this is to ensure the user gets reasonable elements if he
    # does not specify the backends for every specified element of
    # the pipeline
    before  => $required_middlewares,
    require => Package['swift'],
  }
}
