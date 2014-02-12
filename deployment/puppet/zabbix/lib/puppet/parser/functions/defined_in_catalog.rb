#defined_in_catalog.rb
module Puppet::Parser::Functions

  newfunction(:defined_in_catalog, :type => :rvalue, :doc => <<-ENDHEREDOC
    Defined_in_catalog returns true if class exists in catalog or false otherwise

    Usage:

      if ! defined_in_catalog('class::name') {
        notify{ "class is not defined in catalog for host ${::fqdn}...": }
    ENDHEREDOC

  ) do |args|
    raise(Puppet::ParseError, "defined_in_catalog(): Wrong number of arguments (#{args.length}; must be = 1)") unless args.length == 1

    unless args[0].is_a?(String)

      raise Puppet::ParseError, ("defined_in_catalog(): argument must be a string")
    end

    #compiler.catalog.classes.each do |def_class|
    #  puts 'defined class: ' + def_class
    #end

    puts 'compiler.catalog attrs:'
    compiler.catalog.attributes.each do |attr|
      purs '    ' + attr
    end
    return compiler.catalog.classes.include?(args[0])
  end
end
