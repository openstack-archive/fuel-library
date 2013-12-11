class corosync::commitorder {
  include 'heat::params'
  include 'ceilometer::params'
 
  $heat = $heat::params::engine_service_name
  $haproxy = 'p_haproxy'
  $mysql = 'mysql'
  $galera = 'p_mysql'
  $ceilometer_central = "p_${ceilometer::params::agent_central_service_name}"
  $ceilometer_alarm = "p_${ceilometer::params::alarm_evaluator_service}"
  $metadata = 'p_neutron-metadata-agent'
  $ovs = 'ovs'
  $l3 = 'l3'
  $dhcp = 'dhcp'
  
  Cs_shadow <| title == $haproxy |> ->
  Cs_commit <| title == $haproxy |> ->

  Cs_shadow <| title == $mysql |> ->
  Cs_commit <| title == $mysql |> ->

  Cs_shadow <| title == $galera |> ->
  Cs_commit <| title == $galera |> ->

  Cs_shadow <| title == $metadata |> ->
  Cs_commit <| title == $metadata |> ->

  Cs_shadow <| title == $ovs |> ->
  Cs_commit <| title == $ovs |> ->

  Cs_shadow <| title == $dhcp |> ->
  Cs_commit <| title == $dhcp |> ->

  Cs_shadow <| title == $l3 |> ->
  Cs_commit <| title == $l3 |> ->

  Cs_shadow <| title == $heat |> ->
  Cs_commit <| title == $heat |> ->

  Cs_shadow <| title == $ceilometer_central |> ->
  Cs_commit <| title == $ceilometer_central |> ->

  Cs_shadow <| title == $ceilometer_alarm |> ->
  Cs_commit <| title == $ceilometer_alarm |> ->

  notify { 'Corosync commit order have been set!' :}
  
}
