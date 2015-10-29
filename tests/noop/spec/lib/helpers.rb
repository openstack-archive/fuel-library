module Noop::Helpers
  # extract a parameter value from a resource in the catalog
  def resource_parameter_value(context, resource_type, resource_name, parameter)
    catalog = context.subject
    catalog = catalog.call if catalog.is_a? Proc
    resource = catalog.resource resource_type, resource_name
    fail "No resource type: '#{resource_type}' name: '#{resource_name}' in the catalog!" unless resource
    resource[parameter.to_sym]
  end

  # save the current puppet scope
  def puppet_scope=(value)
    @puppet_scope = value
  end

  def puppet_scope
    return @puppet_scope if @puppet_scope
    PuppetlabsSpec::PuppetInternals.scope
  end

  # load a puppet function if it's not alreay loaded
  def puppet_function_load(name)
    name = name.to_sym unless name.is_a? Symbol
    Puppet::Parser::Functions.autoloader.load name
  end

  # call a puppet function and return it's value
  def puppet_function(name, *args)
    name = name.to_sym unless name.is_a? Symbol
    puppet_function_load name
    fail "Could not load Puppet function '#{name}'!" unless puppet_scope.respond_to? "function_#{name}".to_sym
    puppet_scope.send "function_#{name}".to_sym, args
  end

  def lookupvar(name)
    puppet_scope.lookupvar name
  end

end
