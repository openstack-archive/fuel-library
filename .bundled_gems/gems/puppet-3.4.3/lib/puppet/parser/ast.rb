# the parent class for all of our syntactical objects

require 'puppet'
require 'puppet/util/autoload'

# The base class for all of the objects that make up the parse trees.
# Handles things like file name, line #, and also does the initialization
# for all of the parameters of all of the child objects.
class Puppet::Parser::AST
  # Do this so I don't have to type the full path in all of the subclasses
  AST = Puppet::Parser::AST

  include Puppet::Util::Errors
  include Puppet::Util::MethodHelper
  include Puppet::Util::Docs

  attr_accessor :parent, :scope, :file, :line, :pos

  def inspect
    "( #{self.class} #{self.to_s} #{@children.inspect} )"
  end

  # don't fetch lexer comment by default
  def use_docs
    self.class.use_docs
  end

  # allow our subclass to specify they want documentation
  class << self
    attr_accessor :use_docs
    def associates_doc
      self.use_docs = true
    end
  end

  # Evaluate the current object.  Just a stub method, since the subclass
  # should override this method.
  def evaluate(*options)
    raise Puppet::DevError, "Did not override #evaluate in #{self.class}"
  end

  # Throw a parse error.
  def parsefail(message)
    self.fail(Puppet::ParseError, message)
  end

  # Wrap a statemp in a reusable way so we always throw a parse error.
  def parsewrap
    exceptwrap :type => Puppet::ParseError do
      yield
    end
  end

  # The version of the evaluate method that should be called, because it
  # correctly handles errors.  It is critical to use this method because
  # it can enable you to catch the error where it happens, rather than
  # much higher up the stack.
  def safeevaluate(*options)
    # We duplicate code here, rather than using exceptwrap, because this
    # is called so many times during parsing.
    begin
      return self.evaluate(*options)
    rescue Puppet::Error => detail
      raise adderrorcontext(detail)
    rescue => detail
      error = Puppet::ParseError.new(detail.to_s, nil, nil, detail)
      # We can't use self.fail here because it always expects strings,
      # not exceptions.
      raise adderrorcontext(error, detail)
    end
  end

  # Initialize the object.  Requires a hash as the argument, and
  # takes each of the parameters of the hash and calls the settor
  # method for them.  This is probably pretty inefficient and should
  # likely be changed at some point.
  def initialize(args)
    set_options(args)
  end

  # evaluate ourselves, and match
  def evaluate_match(value, scope)
    obj = self.safeevaluate(scope)

    obj   = obj.downcase   if obj.respond_to?(:downcase)
    value = value.downcase if value.respond_to?(:downcase)

    obj   = Puppet::Parser::Scope.number?(obj)   || obj
    value = Puppet::Parser::Scope.number?(value) || value

    # "" == undef for case/selector/if
    obj == value or (obj == "" and value == :undef) or (obj == :undef and value == "")
  end
end

# And include all of the AST subclasses.
require 'puppet/parser/ast/arithmetic_operator'
require 'puppet/parser/ast/astarray'
require 'puppet/parser/ast/asthash'
require 'puppet/parser/ast/boolean_operator'
require 'puppet/parser/ast/branch'
require 'puppet/parser/ast/caseopt'
require 'puppet/parser/ast/casestatement'
require 'puppet/parser/ast/collection'
require 'puppet/parser/ast/collexpr'
require 'puppet/parser/ast/comparison_operator'
require 'puppet/parser/ast/definition'
require 'puppet/parser/ast/else'
require 'puppet/parser/ast/function'
require 'puppet/parser/ast/hostclass'
require 'puppet/parser/ast/ifstatement'
require 'puppet/parser/ast/in_operator'
require 'puppet/parser/ast/lambda'
require 'puppet/parser/ast/leaf'
require 'puppet/parser/ast/match_operator'
require 'puppet/parser/ast/method_call'
require 'puppet/parser/ast/minus'
require 'puppet/parser/ast/node'
require 'puppet/parser/ast/nop'
require 'puppet/parser/ast/not'
require 'puppet/parser/ast/relationship'
require 'puppet/parser/ast/resource'
require 'puppet/parser/ast/resource_defaults'
require 'puppet/parser/ast/resource_instance'
require 'puppet/parser/ast/resource_override'
require 'puppet/parser/ast/resource_reference'
require 'puppet/parser/ast/resourceparam'
require 'puppet/parser/ast/selector'
require 'puppet/parser/ast/tag'
require 'puppet/parser/ast/vardef'
