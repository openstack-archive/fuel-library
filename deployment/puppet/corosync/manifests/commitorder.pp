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
  
#  anchor  {"cib-haproxy-start":} ->
#  anchor  {"cib-haproxy-end":} ->
  anchor  {"cib-mysql-start":} ->
  anchor  {"cib-mysql-end":} ->
  anchor  {"cib-galera-start":} ->
  anchor  {"cib-galera-end":} ->
  anchor  {"cib-metadata-start":} ->
  anchor  {"cib-metadata-end":} ->
  anchor  {"cib-ovs-start":} ->
  anchor  {"cib-ovs-end":} ->
  anchor  {"cib-dhcp-start":} ->
  anchor  {"cib-dhcp-end":} ->
  anchor  {"cib-l3-start":} ->
  anchor  {"cib-l3-end":} ->
  anchor  {"cib-heat-start":} ->
  anchor  {"cib-heat-end":} ->
  anchor  {"cib-ceilometer-central-start":} ->
  anchor  {"cib-ceilometer-central-end":} -> 
  anchor  {"cib-ceilometer-alarm-start":} ->
  anchor  {"cib-ceilometer-alarm-end":} 

#  Anchor["cib-haproxy-start"] -> Cs_shadow <| title == $haproxy |> ->  Cs_commit <| title == $haproxy |> -> Anchor["cib-haproxy-end"]

  Anchor["cib-mysql-start"] -> Cs_shadow <| title == $mysql |> ->  Cs_commit <| title == $mysql |> -> Anchor["cib-mysql-end"]

  Anchor["cib-galera-start"] ->  Cs_shadow <| title == $galera |> ->  Cs_commit <| title == $galera |> -> Anchor["cib-galera-end"]

  Anchor["cib-metadata-start"] -> Cs_shadow <| title == $metadata |> ->  Cs_commit <| title == $metadata |> -> Anchor["cib-metadata-end"]

  Anchor["cib-ovs-start"] -> Cs_shadow <| title == $ovs |> ->  Cs_commit <| title == $ovs |> -> Anchor["cib-ovs-end"]

  Anchor["cib-dhcp-start"] -> Cs_shadow <| title == $dhcp |> ->  Cs_commit <| title == $dhcp |> -> Anchor["cib-dhcp-end"]

  Anchor["cib-l3-start"] -> Cs_shadow <| title == $l3 |> ->  Cs_commit <| title == $l3 |> -> Anchor["cib-l3-end"]

  Anchor["cib-heat-start"] -> Cs_shadow <| title == $heat |> ->  Cs_commit <| title == $heat |> -> Anchor ["cib-heat-end"]

  Anchor["cib-ceilometer-central-start"] -> Cs_shadow <| title == $ceilometer_central |> -> Cs_commit <| title == $ceilometer_central |> -> Anchor["cib-ceilometer-central-end"] 

  Anchor ["cib-ceilometer-alarm-start"]-> Cs_shadow <| title == $ceilometer_alarm |> ->  Cs_commit <| title == $ceilometer_alarm |> -> Anchor["cib-ceilometer-alarm-end"]

  notify { 'Corosync commit order have been set!' :}
  
}
