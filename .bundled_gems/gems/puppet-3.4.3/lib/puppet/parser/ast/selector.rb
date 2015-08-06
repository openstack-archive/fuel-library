require 'puppet/parser/ast/branch'

class Puppet::Parser::AST
  # The inline conditional operator.  Unlike CaseStatement, which executes
  # code, we just return a value.
  class Selector < AST::Branch
    attr_accessor :param, :values

    def each
      [@param,@values].each { |child| yield child }
    end

    # Find the value that corresponds with the test.
    def evaluate(scope)
      level = scope.ephemeral_level
      # Get our parameter.
      paramvalue = @param.safeevaluate(scope)

      default = nil

      @values = [@values] unless @values.instance_of? AST::ASTArray or @values.instance_of? Array

      # Then look for a match in the options.
      @values.each do |obj|
        # short circuit asap if we have a match
        return obj.value.safeevaluate(scope) if obj.param.evaluate_match(paramvalue, scope)

        # Store the default, in case it's necessary.
        default = obj if obj.param.is_a?(Default)
      end

      # Unless we found something, look for the default.
      return default.value.safeevaluate(scope) if default

      self.fail Puppet::ParseError, "No matching value for selector param '#{paramvalue}'"
    ensure
      scope.unset_ephemeral_var(level)
    end

    def to_s
      if @values.instance_of? AST::ASTArray or @values.instance_of? Array
        v = @values
      else
        v = [@values]
      end

      param.to_s + " ? { " + v.collect { |v| v.to_s }.join(', ') + " }"
    end
  end
end
