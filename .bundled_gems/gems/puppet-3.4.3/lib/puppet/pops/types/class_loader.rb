require 'rgen/metamodel_builder'

# The ClassLoader provides a Class instance given a class name or a meta-type.
# If the class is not already loaded, it is loaded using the Puppet Autoloader.
# This means it can load a class from a gem, or from puppet modules.
#
class Puppet::Pops::Types::ClassLoader
  @autoloader = Puppet::Util::Autoload.new("ClassLoader", "", :wrap => false)

  # Returns a Class given a fully qualified class name.
  # Lookup of class is never relative to the calling namespace.
  # @param name [String, Array<String>, Array<Symbol>, Puppet::Pops::Types::PObjectType] A fully qualified
  #   class name String (e.g. '::Foo::Bar', 'Foo::Bar'), a PObjectType, or a fully qualified name in Array form where each part
  #   is either a String or a Symbol, e.g. `%w{Puppetx Puppetlabs SomeExtension}`.
  # @return [Class, nil] the looked up class or nil if no such class is loaded
  # @raise ArgumentError If the given argument has the wrong type
  # @api public
  #
  def self.provide(name)
    case name
    when String
      provide_from_string(name)

    when Array
      provide_from_name_path(name.join('::'), name)

    when Puppet::Pops::Types::PObjectType, Puppet::Pops::Types::PType
      provide_from_type(name)

    else
      raise ArgumentError, "Cannot provide a class from a '#{name.class.name}'"
    end
  end

  private

  def self.provide_from_type(type)
    case type
    when Puppet::Pops::Types::PRubyType
      provide_from_string(type.ruby_class)

    when Puppet::Pops::Types::PBooleanType
      # There is no other thing to load except this Enum meta type
      RGen::MetamodelBuilder::MMBase::Boolean

    when Puppet::Pops::Types::PType
      # TODO: PType should have a type argument (a PObjectType)
      Class

    # Although not expected to be the first choice for getting a concrete class for these
    # types, these are of value if the calling logic just has a reference to type.
    #
    when Puppet::Pops::Types::PArrayType   ; Array
    when Puppet::Pops::Types::PHashType    ; Hash
    when Puppet::Pops::Types::PPatternType ; Regexp
    when Puppet::Pops::Types::PIntegerType ; Integer
    when Puppet::Pops::Types::PStringType  ; String
    when Puppet::Pops::Types::PFloatType   ; Float
    when Puppet::Pops::Types::PNilType     ; NilClass
    else
      nil
    end
  end

  def self.provide_from_string(name)
    name_path = name.split('::')
    # always from the root, so remove an empty first segment
    if name_path[0].empty?
      name_path = name_path[1..-1]
    end
    provide_from_name_path(name, name_path)
  end

  def self.provide_from_name_path(name, name_path)
    # If class is already loaded, try this first
    result = find_class(name_path)

    unless result.is_a?(Class)
      # Attempt to load it using the auto loader
      loaded_path = nil
      if paths_for_name(name).find {|path| loaded_path = path; @autoloader.load(path) }
        result = find_class(name_path)
        unless result.is_a?(Class)
          raise RuntimeError, "Loading of #{name} using relative path: '#{loaded_path}' did not create expected class"
        end
      end
    end
    return nil unless result.is_a?(Class)
    result
  end

  def self.find_class(name_path)
    name_path.reduce(Object) do |ns, name|
      begin
        ns.const_get(name)
      rescue NameError
        return nil
      end
    end
  end

  def self.paths_for_name(fq_name)
    [de_camel(fq_name), downcased_path(fq_name)]
  end

  def self.downcased_path(fq_name)
    fq_name.to_s.gsub(/::/, '/').downcase
  end

  def self.de_camel(fq_name)
    fq_name.to_s.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end

end