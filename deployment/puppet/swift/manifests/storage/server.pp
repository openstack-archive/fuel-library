# == Define: swift::storage::server
#
# Configures an account, container or object server
#
# === Parameters:
#
# [*title*] The port the server will be exposed to
#   Mandatory. Usually 6000, 6001 and 6002 for respectively
#   object, container and account.
#
# [*type*]
#   (required) The type of device, e.g. account, object, or container.
#
# [*storage_local_net_ip*]
#   (required) This is the ip that the storage service will bind to when it starts.
#
# [*devices*]
#   (optional) The directory where the physical storage device will be mounted.
#   Defaults to '/srv/node'.
#
# [*owner*]
#   (optional) Owner (uid) of rsync server.
#   Defaults to 'swift'.
#
# [*group*]
#   (optional) Group (gid) of rsync server.
#   Defaults to 'swift'.
#
# [*max_connections*]
#   (optional) maximum number of simultaneous connections allowed.
#   Defaults to 25.
#
# [*incoming_chmod*] Incoming chmod to set in the rsync server.
#   Optional. Defaults to 0644 for maintaining backwards compatibility.
#   *NOTE*: Recommended parameter: 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r'
#   This mask translates to 0755 for directories and 0644 for files.
#
# [*outgoing_chmod*] Outgoing chmod to set in the rsync server.
#   Optional. Defaults to 0644 for maintaining backwards compatibility.
#   *NOTE*: Recommended parameter: 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r'
#   This mask translates to 0755 for directories and 0644 for files.
#

# [*pipeline*]
#   (optional) Pipeline of applications.
#   Defaults to ["${type}-server"].
#
# [*mount_check*]
#   (optional) Whether or not check if the devices are mounted to prevent accidentally
#   writing to the root device
#   Defaults to false.
#
# [*user*]
#   (optional) User to run as
#   Defaults to 'swift'.
#
# [*workers*]
#   (optional) Override the number of pre-forked workers that will accept
#   connections. If set it should be an integer, zero means no fork. If unset,
#   it will try to default to the number of effective cpu cores and fallback to
#   one. Increasing the number of workers may reduce the possibility of slow file
#   system operations in one request from negatively impacting other requests.
#   See http://docs.openstack.org/developer/swift/deployment_guide.html#general-service-tuning
#   Defaults to '1'.
#
# [*allow_versions*]
#   (optional) Enable/Disable object versioning feature
#   Defaults to 'false'.
#
# [*replicator_concurrency*]
#   (optional) Number of replicator workers to spawn.
#   Defaults to $::processorcount.
#
# [*updater_concurrency*]
#   (optional) Number of updater workers to spawn.
#   Defaults to $::processorcount.
#
# [*reaper_concurrency*]
#   (optional) Number of reaper workers to spawn.
#   Defaults to $::processorcount.
#
# [*log_facility*]
#   (optional) Syslog log facility.
#   Defaults to 'LOG_LOCAL2'.
#
# [*log_level*]
#   (optional) Logging level.
#   Defaults to 'INFO'.
#
# [*log_address*]
#   Deprecated, this parameter does nothing.
#
# [*log_name*]
#   (optional) Label used when logging.
#   Defaults to "${type}-server".

# [*log_udp_host*]
#   (optional) If not set, the UDP receiver for syslog is disabled.
#   Defaults to undef.
#
# [*log_udp_port*]
#   (optional) Port value for UDP receiver, if enabled.
#   Defaults to undef.
#
# [*config_file_path*]
#   (optional) The configuration file name.
#   Defaults to "${type}-server/${name}.conf".
#
define swift::storage::server(
  $type,
  $storage_local_net_ip,
  $devices                = '/srv/node',
  $owner                  = 'swift',
  $group                  = 'swift',
  $incoming_chmod         = '0644',
  $outgoing_chmod         = '0644',
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
  $log_udp_host           = undef,
  $log_udp_port           = undef,
  # this parameters needs to be specified after type and name
  $config_file_path       = "${type}-server/${name}.conf"
) {

  if ($incoming_chmod == '0644') {
    warning('The default incoming_chmod set to 0644 may yield in error prone directories and will be changed in a later release.')
  }

  if ($outgoing_chmod == '0644') {
    warning('The default outgoing_chmod set to 0644 may yield in error prone directories and will be changed in a later release.')
  }

  # Warn if ${type-server} isn't included in the pipeline
  if is_array($pipeline) {
    if !member($pipeline, "${type}-server") {
      warning("swift storage server ${type} must specify ${type}-server")
    }
  } elsif $pipeline != "${type}-server" {
    warning("swift storage server ${type} must specify ${type}-server")
  }

  if ($log_udp_port and !$log_udp_host) {
    fail ('log_udp_port requires log_udp_host to be set')
  }

  include "::swift::storage::${type}"
  include ::concat::setup

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
    incoming_chmod  => $incoming_chmod,
    outgoing_chmod  => $outgoing_chmod,
    max_connections => $max_connections,
    read_only       => false,
  }

  concat { "/etc/swift/${config_file_path}":
    owner   => $owner,
    group   => $group,
    notify  => Service["swift-${type}", "swift-${type}-replicator"],
    require => Package['swift'],
    mode    => '0640',
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
