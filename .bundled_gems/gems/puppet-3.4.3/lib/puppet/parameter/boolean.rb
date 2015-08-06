require 'puppet/coercion'

# This specialized {Puppet::Parameter} handles boolean options, accepting lots
# of strings and symbols for both truthiness and falsehood.
#
class Puppet::Parameter::Boolean < Puppet::Parameter
  def unsafe_munge(value)
    Puppet::Coercion.boolean(value)
  end

  def self.initvars
    super
    @value_collection.newvalues(*Puppet::Coercion.boolean_values)
  end
end
