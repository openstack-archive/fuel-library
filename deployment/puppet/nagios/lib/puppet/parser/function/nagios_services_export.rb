# Parse array and add value to the Puppet resource
require 'puppet/parser/functions'

Puppet::Parser::Functions.newfunction(:nagios_services_export,
                                     :type => :statement,
                                     :doc => <<-'ENDOFDOC'
Create exported nagios_service resourse with array params
  for examples:

  nagios_services_export( $services, $services_list,
  {
    'hostgroup_name'  => newgroup,
    'target'  => "/etc/nagios3/services.cfg"
  })
ENDOFDOC
) do |vals|
  type = '@@nagios_service'
  commands, command_list, params = vals
  raise(ArgumentError, 'commands must specify and must be an Array') unless commands.kind_of? Array
  raise(ArgumentError, 'services_list must specify and must be an Hash') unless command_list.kind_of? Hash
  fqdn = lookupvar('{fqdn}')
  params ||= {}
  commands.each { |command|
    params.merge!({'check_command'      => command_list[command],
                  'service_description' => command,
                  'host_name'           => lookupvar('fqdn') })
    Puppet::Parser::Functions.function(:create_resources)
    function_create_resources([type, { command => params}])
  }
end
