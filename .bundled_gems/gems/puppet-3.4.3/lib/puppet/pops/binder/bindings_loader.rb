require 'rgen/metamodel_builder'

# The ClassLoader provides a Class instance given a class name or a meta-type.
# If the class is not already loaded, it is loaded using the Puppet Autoloader.
# This means it can load a class from a gem, or from puppet modules.
#
class Puppet::Pops::Binder::BindingsLoader
  @autoloader = Puppet::Util::Autoload.new("BindingsLoader", "puppet/bindings", :wrap => false)

  # Returns a XXXXX given a fully qualified class name.
  # Lookup of class is never relative to the calling namespace.
  # @param name [String, Array<String>, Array<Symbol>, Puppet::Pops::Types::PObjectType] A fully qualified
  #   class name String (e.g. '::Foo::Bar', 'Foo::Bar'), a PObjectType, or a fully qualified name in Array form where each part
  #   is either a String or a Symbol, e.g. `%w{Puppetx Puppetlabs SomeExtension}`.
  # @return [Class, nil] the looked up class or nil if no such class is loaded
  # @raise ArgumentError If the given argument has the wrong type
  # @api public
  #
  def self.provide(scope, name)
    case name
    when String
      provide_from_string(scope, name)

    when Array
      provide_from_name_path(scope, name.join('::'), name)

    else
      raise ArgumentError, "Cannot provide a bindings from a '#{name.class.name}'"
    end
  end

  # If loadable name exists relative to a a basedir or not. Returns the loadable path as a side effect.
  # @return [String, nil] a loadable path for the given name, or nil
  #
  def self.loadable?(basedir, name)
    # note, "lib" is added by the autoloader
    #
    paths_for_name(name).find {|p| Puppet::FileSystem::File.exist?(File.join(basedir, "lib/puppet/bindings", p)+'.rb') }
  end

  private

  def self.provide_from_string(scope, name)
    name_path = name.split('::')
    # always from the root, so remove an empty first segment
    if name_path[0].empty?
      name_path = name_path[1..-1]
    end
    provide_from_name_path(scope, name, name_path)
  end

  def self.provide_from_name_path(scope, name, name_path)
    # If bindings is already loaded, try this first
    result = Puppet::Bindings.resolve(scope, name)

    unless result
      # Attempt to load it using the auto loader
      paths_for_name(name).find {|path| @autoloader.load(path) }
      result = Puppet::Bindings.resolve(scope, name)
    end
    result
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