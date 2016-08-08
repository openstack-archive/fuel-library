notice('MODULAR: detach-keystone/hiera-override.pp')

$detach_keystone_plugin = hiera('detach-keystone', undef)
$hiera_dir              = '/etc/hiera/plugins'
$plugin_name            = 'detach-keystone'
$plugin_yaml            = "${plugin_name}.yaml"

if $detach_keystone_plugin {
  $network_metadata = hiera_hash('network_metadata')
  if ! $network_metadata['vips']['service_endpoint'] {
    fail('Keystone service endpoint VIP is not defined')
  }
  if ! $network_metadata['vips']['public_service_endpoint'] {
    fail('Keystone service endpoint public VIP is not defined')
  }

  #TODO (holser): Redesign parseyaml and is_bool once [MODULES-2462] applied
  $settings_hash       = parseyaml($detach_keystone_plugin['yaml_additional_config'])

  if is_bool($settings_hash) {
    $settings_hash_real = {}
  } else {
    $settings_hash_real = $settings_hash
  }

  $keystone_vip        = pick($settings_hash_real['remote_keystone'],
                              $network_metadata['vips']['service_endpoint']['ipaddr'])

  $public_keystone_vip = pick($settings_hash_real['remote_keystone'],
                              $network_metadata['vips']['public_service_endpoint']['ipaddr'])

  $nodes_hash          = hiera('nodes')

  if hiera('role', 'none') == 'primary-standalone-keystone' {
    $primary_keystone = 'true'
  } else {
    $primary_keystone = 'false'
  }

  if hiera('role', 'none') =~ /^primary/ {
    $primary_controller = 'true'
  } else {
    $primary_controller = 'false'
  }
  $keystone_roles       =  ['primary-standalone-keystone',
    'standalone-keystone']
  $keystone_nodes       = get_nodes_hash_by_roles($network_metadata,
    $keystone_roles)
  $keystone_address_map = get_node_to_ipaddr_map_by_network_role($keystone_nodes,
    'keystone/api')
  $keystone_nodes_ips   = values($keystone_address_map)
  $keystone_nodes_names = keys($keystone_address_map)
  $memcached_addresses  = ipsort(values(get_node_to_ipaddr_map_by_network_role($keystone_nodes,'mgmt/memcache')))

  case hiera('role', 'none') {
    /keystone/: {
      $corosync_roles      = $keystone_roles
      $corosync_nodes      = $keystone_nodes
      $memcache_roles      = $keystone_roles
      $memcache_nodes      = $keystone_nodes
      $deploy_vrouter      = 'false'
      $keystone_enabled    = 'true'

      #FIXME(mattymo): Allow plugins to depend on each other and update each other
      $detach_rabbitmq_plugin = hiera('detach-rabbitmq', undef)
      if $detach_rabbitmq_plugin {
        $rabbitmq_roles = [ 'standalone-rabbitmq' ]
        $amqp_port = hiera('amqp_ports', '5673')
        $rabbit_nodes = get_nodes_hash_by_roles($network_metadata, $rabbitmq_roles)
        $rabbit_address_map = get_node_to_ipaddr_map_by_network_role($rabbit_nodes, 'mgmt/messaging')
        $amqp_ips = ipsort(values($rabbit_address_map))
        $amqp_hosts = amqp_hosts($amqp_ips, $amqp_port)
      }

    }
    /controller/: {
      $deploy_vrouter   = 'true'
      $keystone_enabled = 'false'
    }
    default: {
      $keystone_enabled = 'false'
    }
  }

  $calculated_content = inline_template('
primary_keystone: <%= @primary_keystone %>
service_endpoint: <%= @keystone_vip %>
public_service_endpoint: <%= @public_keystone_vip %>
keystone_vip: <%= @keystone_vip %>
public_keystone_vip: <%= @public_keystone_vip %>
<% if @keystone_nodes -%>
<% require "yaml" -%>
keystone_nodes:
<%= YAML.dump(@keystone_nodes).sub(/--- *$/,"") %>
<% end -%>
keystone:
  enabled: <%= @keystone_enabled %>
keystone_ipaddresses:
<% if @keystone_nodes_ips -%>
<%
@keystone_nodes_ips.each do |keystone_ip|
%>  - <%= keystone_ip %>
<% end -%>
<% end -%>
<% if @keystone_nodes_names -%>
keystone_names:
<%
@keystone_nodes_names.each do |keystone_name|
%>  - <%= keystone_name %>
<% end -%>
<% end -%>
primary_controller: <%= @primary_controller %>
<% if @corosync_nodes -%>
<% require "yaml" -%>
corosync_nodes:
<%= YAML.dump(@corosync_nodes).sub(/--- *$/,"") %>
<% end -%>
<% if @corosync_roles -%>
corosync_roles:
<%
@corosync_roles.each do |crole|
%>  - <%= crole %>
<% end -%>
<% end -%>
<% if @memcache_nodes -%>
<% require "yaml" -%>
memcache_nodes:
<%= YAML.dump(@memcache_nodes).sub(/--- *$/,"") %>
<% end -%>
<% if @memcache_roles -%>
memcache_roles:
<%
@memcache_roles.each do |mrole|
%>  - <%= mrole %>
<% end -%>
<% end -%>
<% if @memcached_addresses -%>
memcached_addresses:
<%
@memcached_addresses.each do |maddr|
%>  - <%= maddr %>
<% end -%>
<% end -%>
deploy_vrouter: <%= @deploy_vrouter %>
<% if @amqp_hosts -%>
amqp_hosts: <%=  @amqp_hosts %>
<% end -%>
')

  file { '/etc/hiera/override':
    ensure  => directory,
  }

  file { "${hiera_dir}/${plugin_yaml}":
    ensure  => file,
    content => "${detach_keystone_plugin['yaml_additional_config']}\n${calculated_content}\n",
    require => File['/etc/hiera/override'],
  }

  package { 'ruby-deep-merge':
    ensure  => 'installed',
  }

  #FIXME(mattymo): https://bugs.launchpad.net/fuel/+bug/1479317
  package { 'python-openstackclient':
    ensure => latest,
  }
}
