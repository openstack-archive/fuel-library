# == Define: cluster::fencing
#
# Configure VirtualIP resource for corosync/pacemaker.
#
define cluster::fencing (
  $agent_type,
  $parameters    = { },
  $operations    = { },
  $meta          = { },
){
  $cib_name = "stonith__${::hostname}"
  $res_name = "stonith__${title}__${::hostname}"

  ::corosync::cleanup { $res_name: }
  cs_resource { $res_name:
    ensure          => present,
    cib             => $cib_name,
    primitive_class => 'stonith',
    primitive_type  => $agent_type,
    parameters      => $parameters,
    operations      => $operations,
    metadata        => $meta,
  }

  cs_location {"location__$res_name":
    cib        => $cib_name,
    node_name  => $::pacemaker_hostname,
    node_score => '-INFINITY',      # do not use "-inf" notation!!! It will be converted to
    primitive  => $res_name,        # "-INFINITY" by pacemaker CLI, and resource will become
                                    # unenshurable
  }
  Cs_resource[$res_name] ->
  Cs_location["location__$res_name"] ->
  Corosync::Cleanup[$res_name]
}
#
###
