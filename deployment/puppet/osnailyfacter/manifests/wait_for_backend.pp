# == Class: osnailyfacter::wait_for_backend
#
# Class which  
#
# == Parameters
#
# [*lb_hash*]
#  A hash of haproxy_backend_status resources to ensure
#
# [*lb_defaults*]
# A hash of load balancer default settings which should be merged 
#


class osnailyfacter::wait_for_backend (
  $lb_hash = {},
  $lb_defaults = {}
)
{
  ensure_resource_with_default(haproxy_backend_status,$lp_hash,$lp_defaults)
}
