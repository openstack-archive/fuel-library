require 'puppet/parameter/value'

# A collection of values and regular expressions, used for specifying allowed values
# in a given parameter.
# @note This class is considered part of the internal implementation of {Puppet::Parameter}, and
#   {Puppet::Property} and the functionality provided by this class should be used via their interfaces.
# @comment This class probably have several problems when trying to use it with a combination of
#   regular expressions and aliases as it finds an acceptable value holder vi "name" which may be
#   a regular expression...
#
# @api private
#
class Puppet::Parameter::ValueCollection

  # Aliases the given existing _other_ value with the additional given _name_.
  # @return [void]
  # @api private
  #
  def aliasvalue(name, other)
    other = other.to_sym
    unless value = match?(other)
      raise Puppet::DevError, "Cannot alias nonexistent value #{other}"
    end

    value.alias(name)
  end

  # Returns a doc string (enumerating the acceptable values) for all of the values in this parameter/property.
  # @return [String] a documentation string.
  # @api private
  #
  def doc
    unless defined?(@doc)
      @doc = ""
      unless values.empty?
        @doc << "Valid values are "
        @doc << @strings.collect do |value|
          if aliases = value.aliases and ! aliases.empty?
            "`#{value.name}` (also called `#{aliases.join(", ")}`)"
          else
            "`#{value.name}`"
          end
        end.join(", ") << ". "
      end

      unless regexes.empty?
        @doc << "Values can match `#{regexes.join("`, `")}`."
      end
    end

    @doc
  end

  # @return [Boolean] Returns whether the set of allowed values is empty or not.
  # @api private
  #
  def empty?
    @values.empty?
  end

  # @api private
  #
  def initialize
    # We often look values up by name, so a hash makes more sense.
    @values = {}

    # However, we want to retain the ability to match values in order,
    # but we always prefer directly equality (i.e., strings) over regex matches.
    @regexes = []
    @strings = []
  end

  # Checks if the given value is acceptable (matches one of the literal values or patterns) and returns
  # the "matcher" that matched.
  # Literal string matchers are tested first, if both a literal and a regexp match would match, the literal
  # match wins.
  #
  # @param test_value [Object] the value to test if it complies with the configured rules
  # @return [Puppet::Parameter::Value, nil] The instance of Puppet::Parameter::Value that matched the given value, or nil if there was no match.
  # @api private
  #
  def match?(test_value)
    # First look for normal values
    if value = @strings.find { |v| v.match?(test_value) }
      return value
    end

    # Then look for a regex match
    @regexes.find { |v| v.match?(test_value) }
  end

  # Munges the value if it is valid, else produces the same value.
  # @param value [Object] the value to munge
  # @return [Object] the munged value, or the given value
  # @todo This method does not seem to do any munging. It just returns the value if it matches the
  #   regexp, or the (most likely Symbolic) allowed value if it matches (which is more of a replacement
  #   of one instance with an equal one. Is the intent that this method should be specialized?
  # @api private
  #
  def munge(value)
    return value if empty?

    if instance = match?(value)
      if instance.regex?
        return value
      else
        return instance.name
      end
    else
      return value
    end
  end

  # Defines a new valid value for a {Puppet::Property}.
  # A valid value is specified as a literal (typically a Symbol), but can also be
  # specified with a regexp.
  #
  # @param name [Symbol, Regexp] a valid literal value, or a regexp that matches a value
  # @param options [Hash] a hash with options
  # @option options [Symbol] :event The event that should be emitted when this value is set.
  # @todo Option :event original comment says "event should be returned...", is "returned" the correct word
  #   to use?
  # @option options [Symbol] :call When to call any associated block. The default value is `:instead` which
  #   means that the block should be called instead of the provider. In earlier versions (before 20081031) it
  #   was possible to specify a value of `:before` or `:after` for the purpose of calling
  #   both the block and the provider. Use of these deprecated options will now raise an exception later
  #   in the process when the _is_ value is set (see Puppet::Property#set).
  # @option options [Symbol] :invalidate_refreshes True if a change on this property should invalidate and
  #   remove any scheduled refreshes (from notify or subscribe) targeted at the same resource. For example, if
  #   a change in this property takes into account any changes that a scheduled refresh would have performed,
  #   then the scheduled refresh would be deleted.
  # @option options [Object] _any_ Any other option is treated as a call to a setter having the given
  #   option name (e.g. `:required_features` calls `required_features=` with the option's value as an
  #   argument).
  # @api private
  #
  def newvalue(name, options = {}, &block)
    value = Puppet::Parameter::Value.new(name)
    @values[value.name] = value
    if value.regex?
      @regexes << value
    else
      @strings << value
    end

    options.each { |opt, arg| value.send(opt.to_s + "=", arg) }
    if block_given?
      value.block = block
    else
      value.call = options[:call] || :none
    end

    value.method ||= "set_#{value.name}" if block_given? and ! value.regex?

    value
  end

  # Defines one or more valid values (literal or regexp) for a parameter or property.
  # @return [void]
  # @dsl type
  # @api private
  #
  def newvalues(*names)
    names.each { |name| newvalue(name) }
  end

  # @return [Array<String>] An array of the regular expressions in string form, configured as matching valid values.
  # @api private
  #
  def regexes
    @regexes.collect { |r| r.name.inspect }
  end

  # Validates the given value against the set of valid literal values and regular expressions.
  # @raise [ArgumentError] if the value is not accepted
  # @return [void]
  # @api private
  #
  def validate(value)
    return if empty?

    unless @values.detect { |name, v| v.match?(value) }
      str = "Invalid value #{value.inspect}. "

      str += "Valid values are #{values.join(", ")}. " unless values.empty?

      str += "Valid values match #{regexes.join(", ")}." unless regexes.empty?

      raise ArgumentError, str
    end
  end

  # Returns a valid value matcher (a literal or regular expression)
  # @todo This looks odd, asking for an instance that matches a symbol, or an instance that has
  #   a regexp. What is the intention here? Marking as api private...
  #
  # @return [Puppet::Parameter::Value] a valid valud matcher
  # @api private
  #
  def value(name)
    @values[name]
  end

  # @return [Array<Symbol>] Returns a list of valid literal values.
  # @see regexes
  # @api private
  #
  def values
    @strings.collect { |s| s.name }
  end
end
