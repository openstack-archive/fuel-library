require 'puppet/parser/ast/resource_reference'

# Any normal puppet resource declaration.  Can point to a definition or a
# builtin type.
class Puppet::Parser::AST
class Resource < AST::Branch

  associates_doc

  attr_accessor :type, :instances, :exported, :virtual

  # Does not actually return an object; instead sets an object
  # in the current scope.
  def evaluate(scope)
    # We want virtual to be true if exported is true.  We can't
    # just set :virtual => self.virtual in the initialization,
    # because sometimes the :virtual attribute is set *after*
    # :exported, in which case it clobbers :exported if :exported
    # is true.  Argh, this was a very tough one to track down.
    virt = self.virtual || self.exported

    # First level of implicit iteration: build a resource for each
    # instance.  This handles things like:
    # file { '/foo': owner => blah; '/bar': owner => blah }
    @instances.collect { |instance|

      # Evaluate all of the specified params.
      paramobjects = instance.parameters.collect { |param|
        param.safeevaluate(scope)
      }

      resource_titles = instance.title.safeevaluate(scope)

      # it's easier to always use an array, even for only one name
      resource_titles = [resource_titles] unless resource_titles.is_a?(Array)

      fully_qualified_type, resource_titles = scope.resolve_type_and_titles(type, resource_titles)

      # Second level of implicit iteration; build a resource for each
      # title.  This handles things like:
      # file { ['/foo', '/bar']: owner => blah }
      resource_titles.flatten.collect { |resource_title|
        exceptwrap :type => Puppet::ParseError do
          resource = Puppet::Parser::Resource.new(
            fully_qualified_type, resource_title,
            :parameters => paramobjects,
            :file => self.file,
            :line => self.line,
            :exported => self.exported,
            :virtual => virt,
            :source => scope.source,
            :scope => scope,
            :strict => true
          )

          if resource.resource_type.is_a? Puppet::Resource::Type
            resource.resource_type.instantiate_resource(scope, resource)
          end
          scope.compiler.add_resource(scope, resource)
          scope.compiler.evaluate_classes([resource_title], scope, false, true) if fully_qualified_type == 'class'
          resource
        end
      }
    }.flatten.reject { |resource| resource.nil? }
  end
end
end
