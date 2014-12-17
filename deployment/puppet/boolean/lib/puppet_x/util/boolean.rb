module PuppetX
  module Util
  end
end

module PuppetX::Util::Boolean
  module Ontology

    # All values that are considered 'true' by Puppet internals
    def true_values
      [true, 'true', :true, :yes, 'yes']
    end

    # All values that are considered 'false' by Puppet internals
    def false_values
      [false, 'false', :false, :no, 'no', :undef, nil]
    end

    # Normalize Boolean values
    #
    # @param [Object] v Something that vaguely resembles a boolean
    #
    # @raise [ArgumentError] The supplied parameter cannot be normalized.
    #
    # @return [true, false]
    def munge(v)
      if true_values.include? v
        true
      elsif false_values.include? v
        false
      else
        raise ArgumentError, "Value '#{value}':#{value.class} cannot be determined as a boolean value"
      end
    end
  end

  include Ontology
  extend Ontology

  def self.defaultvalues
    newvalue(true)
    newvalue(false)

    aliasvalue(:true, true)
    aliasvalue(:false, false)

    aliasvalue('true', true)
    aliasvalue('false', false)

    aliasvalue(:yes, true)
    aliasvalue(:no, false)

    aliasvalue('yes', true)
    aliasvalue('no', false)

    # Ensure provided values are reasonable by trying to munge them, and if that
    # fails then let munge throw the exception and propagate that up.
    validate do |value|
      munge(value)
    end
  end
end
