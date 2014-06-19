# default params for sysctl
#
# Use this to set default values that are used by this module.
#
#  * exec_path: The path parameter for your exec. Can be handy if you
#               don't want to set a global exec default.
class sysctl::params(
  $exec_path = undef,
) { }
