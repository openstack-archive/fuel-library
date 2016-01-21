# == Class: osnailyfacter::wait_for_backend
#
# Class which wraps around haproxy_backend_status
# and allows one to pass a hash to it and merge
# it with a default hash in order to create
# a set of similar checks for load balancer backends
#
# == Parameters
#
# [*lb_hash*]
#  A hash of haproxy_backend_status resources to ensure
#
# [*lb_defaults*]
# A hash of load balancer default settings which should be merged
#


define osnailyfacter::wait_for_backend (
  $lb_hash     = {},
  $lb_defaults = {},
)
{
  ensure_resource_with_default('haproxy_backend_status',$lb_hash,$lb_defaults)
}
