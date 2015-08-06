require 'puppet/parser/ast/branch'

class Puppet::Parser::AST
  # Define a variable.  Stores the value in the current scope.
  class VarDef < AST::Branch

    associates_doc

    attr_accessor :name, :value, :append

    # Look up our name and value, and store them appropriately.  The
    # lexer strips off the syntax stuff like '$'.
    def evaluate(scope)
      value = @value.safeevaluate(scope)
      if name.is_a?(HashOrArrayAccess)
        name.assign(scope, value)
      else
        name = @name.safeevaluate(scope)

        parsewrap do
          scope.setvar(name,value, :file => file, :line => line, :append => @append)
        end
      end
      if @append
        # Produce resulting value from append operation
        scope[name]
      else
        # Produce assigned value
        value
      end
    end

    def each
      [@name,@value].each { |child| yield child }
    end
  end

end
