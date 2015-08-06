# Requires the specified classes

  Puppet::Parser::Functions::newfunction(
    :require,
    :arity => -2,
    :doc =>"Evaluate one or more classes,  adding the required class as a dependency.

The relationship metaparameters work well for specifying relationships
between individual resources, but they can be clumsy for specifying
relationships between classes.  This function is a superset of the
'include' function, adding a class relationship so that the requiring
class depends on the required class.

Warning: using require in place of include can lead to unwanted dependency cycles.

For instance the following manifest, with 'require' instead of 'include' would produce a nasty dependence cycle, because notify imposes a before between File[/foo] and Service[foo]:

    class myservice {
      service { foo: ensure => running }
    }

    class otherstuff {
      include myservice
      file { '/foo': notify => Service[foo] }
    }

Note that this function only works with clients 0.25 and later, and it will
fail if used with earlier clients.

") do |vals|
  # Verify that the 'include' function is loaded
  method = Puppet::Parser::Functions.function(:include)

  send(method, vals)
  vals = [vals] unless vals.is_a?(Array)

  vals.each do |klass|
    # lookup the class in the scopes
    if classobj = find_hostclass(klass)
      klass = classobj.name
    else
      raise Puppet::ParseError, "Could not find class #{klass}"
    end

    # This is a bit hackish, in some ways, but it's the only way
    # to configure a dependency that will make it to the client.
    # The 'obvious' way is just to add an edge in the catalog,
    # but that is considered a containment edge, not a dependency
    # edge, so it usually gets lost on the client.
    ref = Puppet::Resource.new(:class, klass)
    resource.set_parameter(:require, [resource[:require]].flatten.compact << ref)
  end
end
