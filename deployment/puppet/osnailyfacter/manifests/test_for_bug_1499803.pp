class corosync(
  $test_param        = hiera_array('test_roles', keys($rgw_address_map))
)
