require 'puppet/util/autoload'
require 'puppet/parser/scope'

# A module for managing parser functions.  Each specified function
# is added to a central module that then gets included into the Scope
# class.
#
# @api public
module Puppet::Parser::Functions
  Environment = Puppet::Node::Environment

  class << self
    include Puppet::Util
  end

  # Reset the list of loaded functions.
  #
  # @api private
  def self.reset
    @functions = Hash.new { |h,k| h[k] = {} }
    @modules = Hash.new

    # Runs a newfunction to create a function for each of the log levels
    Puppet::Util::Log.levels.each do |level|
      newfunction(level, :doc => "Log a message on the server at level #{level.to_s}.") do |vals|
        send(level, vals.join(" "))
      end
    end
  end

  # Accessor for singleton autoloader
  #
  # @api private
  def self.autoloader
    @autoloader ||= Puppet::Util::Autoload.new(
      self, "puppet/parser/functions", :wrap => false
    )
  end

  # Get the module that functions are mixed into corresponding to an
  # environment
  #
  # @api private
  def self.environment_module(env = nil)
    if env and ! env.is_a?(Puppet::Node::Environment)
      env = Puppet::Node::Environment.new(env)
    end
    @modules[ (env || Environment.current || Environment.root).name ] ||= Module.new
  end

  # Create a new Puppet DSL function.
  #
  # **The {newfunction} method provides a public API.**
  #
  # This method is used both internally inside of Puppet to define parser
  # functions.  For example, template() is defined in
  # {file:lib/puppet/parser/functions/template.rb template.rb} using the
  # {newfunction} method.  Third party Puppet modules such as
  # [stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib) use this method to
  # extend the behavior and functionality of Puppet.
  #
  # See also [Docs: Custom
  # Functions](http://docs.puppetlabs.com/guides/custom_functions.html)
  #
  # @example Define a new Puppet DSL Function
  #     >> Puppet::Parser::Functions.newfunction(:double, :arity => 1,
  #          :doc => "Doubles an object, typically a number or string.",
  #          :type => :rvalue) {|i| i[0]*2 }
  #     => {:arity=>1, :type=>:rvalue,
  #         :name=>"function_double",
  #         :doc=>"Doubles an object, typically a number or string."}
  #
  # @example Invoke the double function from irb as is done in RSpec examples:
  #     >> scope = Puppet::Parser::Scope.new_for_test_harness('example')
  #     => Scope()
  #     >> scope.function_double([2])
  #     => 4
  #     >> scope.function_double([4])
  #     => 8
  #     >> scope.function_double([])
  #     ArgumentError: double(): Wrong number of arguments given (0 for 1)
  #     >> scope.function_double([4,8])
  #     ArgumentError: double(): Wrong number of arguments given (2 for 1)
  #     >> scope.function_double(["hello"])
  #     => "hellohello"
  #
  # @param [Symbol] name the name of the function represented as a ruby Symbol.
  #   The {newfunction} method will define a Ruby method based on this name on
  #   the parser scope instance.
  #
  # @param [Proc] block the block provided to the {newfunction} method will be
  #   executed when the Puppet DSL function is evaluated during catalog
  #   compilation.  The arguments to the function will be passed as an array to
  #   the first argument of the block.  The return value of the block will be
  #   the return value of the Puppet DSL function for `:rvalue` functions.
  #
  # @option options [:rvalue, :statement] :type (:statement) the type of function.
  #   Either `:rvalue` for functions that return a value, or `:statement` for
  #   functions that do not return a value.
  #
  # @option options [String] :doc ('') the documentation for the function.
  #   This string will be extracted by documentation generation tools.
  #
  # @option options [Integer] :arity (-1) the
  #   [arity](http://en.wikipedia.org/wiki/Arity) of the function.  When
  #   specified as a positive integer the function is expected to receive
  #   _exactly_ the specified number of arguments.  When specified as a
  #   negative number, the function is expected to receive _at least_ the
  #   absolute value of the specified number of arguments incremented by one.
  #   For example, a function with an arity of `-4` is expected to receive at
  #   minimum 3 arguments.  A function with the default arity of `-1` accepts
  #   zero or more arguments.  A function with an arity of 2 must be provided
  #   with exactly two arguments, no more and no less.  Added in Puppet 3.1.0.
  #
  # @return [Hash] describing the function.
  #
  # @api public
  def self.newfunction(name, options = {}, &block)
    name = name.intern

    Puppet.warning "Overwriting previous definition for function #{name}" if get_function(name)

    arity = options[:arity] || -1
    ftype = options[:type] || :statement

    unless ftype == :statement or ftype == :rvalue
      raise Puppet::DevError, "Invalid statement type #{ftype.inspect}"
    end

    # the block must be installed as a method because it may use "return",
    # which is not allowed from procs.
    real_fname = "real_function_#{name}"
    environment_module.send(:define_method, real_fname, &block)

    fname = "function_#{name}"
    environment_module.send(:define_method, fname) do |*args|
      Puppet::Util::Profiler.profile("Called #{name}") do
        if args[0].is_a? Array
          if arity >= 0 and args[0].size != arity
            raise ArgumentError, "#{name}(): Wrong number of arguments given (#{args[0].size} for #{arity})"
          elsif arity < 0 and args[0].size < (arity+1).abs
            raise ArgumentError, "#{name}(): Wrong number of arguments given (#{args[0].size} for minimum #{(arity+1).abs})"
          end
          self.send(real_fname, args[0])
        else
          raise ArgumentError, "custom functions must be called with a single array that contains the arguments. For example, function_example([1]) instead of function_example(1)"
        end
      end
    end

    func = {:arity => arity, :type => ftype, :name => fname}
    func[:doc] = options[:doc] if options[:doc]

    add_function(name, func)
    func
  end

  # Determine if a function is defined
  #
  # @param [Symbol] name the function
  #
  # @return [Symbol, false] The name of the function if it's defined,
  #   otherwise false.
  #
  # @api public
  def self.function(name)
    name = name.intern

    func = nil
    unless func = get_function(name)
      autoloader.load(name, Environment.current)
      func = get_function(name)
    end

    if func
      func[:name]
    else
      false
    end
  end

  def self.functiondocs
    autoloader.loadall

    ret = ""

    merged_functions.sort { |a,b| a[0].to_s <=> b[0].to_s }.each do |name, hash|
      ret << "#{name}\n#{"-" * name.to_s.length}\n"
      if hash[:doc]
        ret << Puppet::Util::Docs.scrub(hash[:doc])
      else
        ret << "Undocumented.\n"
      end

      ret << "\n\n- *Type*: #{hash[:type]}\n\n"
    end

    ret
  end

  # Determine whether a given function returns a value.
  #
  # @param [Symbol] name the function
  #
  # @api public
  def self.rvalue?(name)
    func = get_function(name)
    func ? func[:type] == :rvalue : false
  end

  # Return the number of arguments a function expects.
  #
  # @param [Symbol] name the function
  # @return [Integer] The arity of the function. See {newfunction} for
  #   the meaning of negative values.
  #
  # @api public
  def self.arity(name)
    func = get_function(name)
    func ? func[:arity] : -1
  end

  class << self
    private

    def merged_functions
      @functions[Environment.root].merge(@functions[Environment.current])
    end

    def get_function(name)
      name = name.intern
      merged_functions[name]
    end

    def add_function(name, func)
      name = name.intern
      @functions[Environment.current][name] = func
    end
  end

  reset  # initialize the class instance variables
end
