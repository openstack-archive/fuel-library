require 'puppet/node'
require 'puppet/indirector'
require 'puppet/transaction'
require 'puppet/util/pson'
require 'puppet/util/tagging'
require 'puppet/graph'

# This class models a node catalog.  It is the thing meant to be passed
# from server to client, and it contains all of the information in the
# catalog, including the resources and the relationships between them.
#
# @api public

class Puppet::Resource::Catalog < Puppet::Graph::SimpleGraph
  class DuplicateResourceError < Puppet::Error
    include Puppet::ExternalFileError
  end

  extend Puppet::Indirector
  indirects :catalog, :terminus_setting => :catalog_terminus

  include Puppet::Util::Tagging
  extend Puppet::Util::Pson

  # The host name this is a catalog for.
  attr_accessor :name

  # The catalog version.  Used for testing whether a catalog
  # is up to date.
  attr_accessor :version

  # How long this catalog took to retrieve.  Used for reporting stats.
  attr_accessor :retrieval_duration

  # Whether this is a host catalog, which behaves very differently.
  # In particular, reports are sent, graphs are made, and state is
  # stored in the state database.  If this is set incorrectly, then you often
  # end up in infinite loops, because catalogs are used to make things
  # that the host catalog needs.
  attr_accessor :host_config

  # Whether this catalog was retrieved from the cache, which affects
  # whether it is written back out again.
  attr_accessor :from_cache

  # Some metadata to help us compile and generally respond to the current state.
  attr_accessor :client_version, :server_version

  # The environment for this catalog
  attr_accessor :environment

  # Add classes to our class list.
  def add_class(*classes)
    classes.each do |klass|
      @classes << klass
    end

    # Add the class names as tags, too.
    tag(*classes)
  end

  def title_key_for_ref( ref )
    ref =~ /^([-\w:]+)\[(.*)\]$/m
    [$1, $2]
  end

  def add_resource(*resources)
    resources.each do |resource|
      add_one_resource(resource)
    end
  end

  # @param resource [A Resource] a resource in the catalog
  # @return [A Resource, nil] the resource that contains the given resource
  # @api public
  def container_of(resource)
    adjacent(resource, :direction => :in)[0]
  end

  def add_one_resource(resource)
    fail_on_duplicate_type_and_title(resource)

    add_resource_to_table(resource)
    create_resource_aliases(resource)

    resource.catalog = self if resource.respond_to?(:catalog=)
    add_resource_to_graph(resource)
  end
  private :add_one_resource

  def add_resource_to_table(resource)
    title_key = title_key_for_ref(resource.ref)
    @resource_table[title_key] = resource
    @resources << title_key
  end
  private :add_resource_to_table

  def add_resource_to_graph(resource)
    add_vertex(resource)
    @relationship_graph.add_vertex(resource) if @relationship_graph
  end
  private :add_resource_to_graph

  def create_resource_aliases(resource)
    if resource.respond_to?(:isomorphic?) and resource.isomorphic? and resource.name != resource.title
      self.alias(resource, resource.uniqueness_key)
    end
  end
  private :create_resource_aliases

  # Create an alias for a resource.
  def alias(resource, key)
    resource.ref =~ /^(.+)\[/
    class_name = $1 || resource.class.name

    newref = [class_name, key].flatten

    if key.is_a? String
      ref_string = "#{class_name}[#{key}]"
      return if ref_string == resource.ref
    end

    # LAK:NOTE It's important that we directly compare the references,
    # because sometimes an alias is created before the resource is
    # added to the catalog, so comparing inside the below if block
    # isn't sufficient.
    if existing = @resource_table[newref]
      return if existing == resource
      resource_declaration = " at #{resource.file}:#{resource.line}" if resource.file and resource.line
      existing_declaration = " at #{existing.file}:#{existing.line}" if existing.file and existing.line
      msg = "Cannot alias #{resource.ref} to #{key.inspect}#{resource_declaration}; resource #{newref.inspect} already declared#{existing_declaration}"
      raise ArgumentError, msg
    end
    @resource_table[newref] = resource
    @aliases[resource.ref] ||= []
    @aliases[resource.ref] << newref
  end

  # Apply our catalog to the local host.
  # @param options [Hash{Symbol => Object}] a hash of options
  # @option options [Puppet::Transaction::Report] :report
  #   The report object to log this transaction to. This is optional,
  #   and the resulting transaction will create a report if not
  #   supplied.
  # @option options [Array[String]] :tags
  #   Tags used to filter the transaction. If supplied then only
  #   resources tagged with any of these tags will be evaluated.
  # @option options [Boolean] :ignoreschedules
  #   Ignore schedules when evaluating resources
  # @option options [Boolean] :for_network_device
  #   Whether this catalog is for a network device
  #
  # @return [Puppet::Transaction] the transaction created for this
  #   application
  #
  # @api public
  def apply(options = {})
    Puppet::Util::Storage.load if host_config?

    transaction = create_transaction(options)

    begin
      transaction.report.as_logging_destination do
        transaction.evaluate
      end
    rescue Puppet::Error => detail
      Puppet.log_exception(detail, "Could not apply complete catalog: #{detail}")
    rescue => detail
      Puppet.log_exception(detail, "Got an uncaught exception of type #{detail.class}: #{detail}")
    ensure
      # Don't try to store state unless we're a host config
      # too recursive.
      Puppet::Util::Storage.store if host_config?
    end

    yield transaction if block_given?

    transaction
  end

  # The relationship_graph form of the catalog. This contains all of the
  # dependency edges that are used for determining order.
  #
  # @return [Puppet::Graph::RelationshipGraph]
  # @api public
  def relationship_graph
    if @relationship_graph.nil?
      @relationship_graph = Puppet::Graph::RelationshipGraph.new(prioritizer)
      @relationship_graph.populate_from(self)
    end
    @relationship_graph
  end

  def clear(remove_resources = true)
    super()
    # We have to do this so that the resources clean themselves up.
    @resource_table.values.each { |resource| resource.remove } if remove_resources
    @resource_table.clear
    @resources = []

    if @relationship_graph
      @relationship_graph.clear
      @relationship_graph = nil
    end
  end

  def classes
    @classes.dup
  end

  # Create a new resource and register it in the catalog.
  def create_resource(type, options)
    unless klass = Puppet::Type.type(type)
      raise ArgumentError, "Unknown resource type #{type}"
    end
    return unless resource = klass.new(options)

    add_resource(resource)
    resource
  end

  # Make sure all of our resources are "finished".
  def finalize
    make_default_resources

    @resource_table.values.each { |resource| resource.finish }

    write_graph(:resources)
  end

  def host_config?
    host_config
  end

  def initialize(name = nil)
    super()
    @name = name if name
    @classes = []
    @resource_table = {}
    @resources = []
    @relationship_graph = nil

    @host_config = true

    @aliases = {}

    if block_given?
      yield(self)
      finalize
    end
  end

  # Make the default objects necessary for function.
  def make_default_resources
    # We have to add the resources to the catalog, or else they won't get cleaned up after
    # the transaction.

    # First create the default scheduling objects
    Puppet::Type.type(:schedule).mkdefaultschedules.each { |res| add_resource(res) unless resource(res.ref) }

    # And filebuckets
    if bucket = Puppet::Type.type(:filebucket).mkdefaultbucket
      add_resource(bucket) unless resource(bucket.ref)
    end
  end

  # Remove the resource from our catalog.  Notice that we also call
  # 'remove' on the resource, at least until resource classes no longer maintain
  # references to the resource instances.
  def remove_resource(*resources)
    resources.each do |resource|
      title_key = title_key_for_ref(resource.ref)
      @resource_table.delete(title_key)
      if aliases = @aliases[resource.ref]
        aliases.each { |res_alias| @resource_table.delete(res_alias) }
        @aliases.delete(resource.ref)
      end
      remove_vertex!(resource) if vertex?(resource)
      @relationship_graph.remove_vertex!(resource) if @relationship_graph and @relationship_graph.vertex?(resource)
      @resources.delete(title_key)
      resource.remove
    end
  end

  # Look a resource up by its reference (e.g., File[/etc/passwd]).
  def resource(type, title = nil)
    # Always create a resource reference, so that it always
    # canonicalizes how we are referring to them.
    if title
      res = Puppet::Resource.new(type, title)
    else
      # If they didn't provide a title, then we expect the first
      # argument to be of the form 'Class[name]', which our
      # Reference class canonicalizes for us.
      res = Puppet::Resource.new(nil, type)
    end
    title_key      = [res.type, res.title.to_s]
    uniqueness_key = [res.type, res.uniqueness_key].flatten
    @resource_table[title_key] || @resource_table[uniqueness_key]
  end

  def resource_refs
    resource_keys.collect{ |type, name| name.is_a?( String ) ? "#{type}[#{name}]" : nil}.compact
  end

  def resource_keys
    @resource_table.keys
  end

  def resources
    @resources.collect do |key|
      @resource_table[key]
    end
  end

  def self.from_pson(data)
    result = new(data['name'])

    if tags = data['tags']
      result.tag(*tags)
    end

    if version = data['version']
      result.version = version
    end

    if environment = data['environment']
      result.environment = environment
    end

    if resources = data['resources']
      result.add_resource(*resources.collect do |res|
        Puppet::Resource.from_pson(res)
      end)
    end

    if edges = data['edges']
      edges = PSON.parse(edges) if edges.is_a?(String)
      edges.each do |edge|
        edge_from_pson(result, edge)
      end
    end

    if classes = data['classes']
      result.add_class(*classes)
    end

    result
  end

  def self.edge_from_pson(result, edge)
    # If no type information was presented, we manually find
    # the class.
    edge = Puppet::Relationship.from_pson(edge) if edge.is_a?(Hash)
    unless source = result.resource(edge.source)
      raise ArgumentError, "Could not convert from pson: Could not find relationship source #{edge.source.inspect}"
    end
    edge.source = source

    unless target = result.resource(edge.target)
      raise ArgumentError, "Could not convert from pson: Could not find relationship target #{edge.target.inspect}"
    end
    edge.target = target

    result.add_edge(edge)
  end

  def to_data_hash
    {
      'tags'      => tags,
      'name'      => name,
      'version'   => version,
      'environment' => environment.to_s,
      'resources' => @resources.collect { |v| @resource_table[v].to_pson_data_hash },
      'edges'     => edges.   collect { |e| e.to_pson_data_hash },
      'classes'   => classes
    }
  end

  PSON.register_document_type('Catalog',self)
  def to_pson_data_hash
    {
      'document_type' => 'Catalog',
      'data'       => to_data_hash,
      'metadata' => {
        'api_version' => 1
        }
    }
  end

  def to_pson(*args)
    to_pson_data_hash.to_pson(*args)
  end

  # Convert our catalog into a RAL catalog.
  def to_ral
    to_catalog :to_ral
  end

  # Convert our catalog into a catalog of Puppet::Resource instances.
  def to_resource
    to_catalog :to_resource
  end

  # filter out the catalog, applying +block+ to each resource.
  # If the block result is false, the resource will
  # be kept otherwise it will be skipped
  def filter(&block)
    to_catalog :to_resource, &block
  end

  # Store the classes in the classfile.
  def write_class_file
    ::File.open(Puppet[:classfile], "w") do |f|
      f.puts classes.join("\n")
    end
  rescue => detail
    Puppet.err "Could not create class file #{Puppet[:classfile]}: #{detail}"
  end

  # Store the list of resources we manage
  def write_resource_file
    ::File.open(Puppet[:resourcefile], "w") do |f|
      to_print = resources.map do |resource|
        next unless resource.managed?
        if resource.name_var
          "#{resource.type}[#{resource[resource.name_var]}]"
        else
          "#{resource.ref.downcase}"
        end
      end.compact
      f.puts to_print.join("\n")
    end
  rescue => detail
    Puppet.err "Could not create resource file #{Puppet[:resourcefile]}: #{detail}"
  end

  # Produce the graph files if requested.
  def write_graph(name)
    # We only want to graph the main host catalog.
    return unless host_config?

    super
  end

  private

  def prioritizer
    @prioritizer ||= case Puppet[:ordering]
                     when "title-hash"
                       Puppet::Graph::TitleHashPrioritizer.new
                     when "manifest"
                       Puppet::Graph::SequentialPrioritizer.new
                     when "random"
                       Puppet::Graph::RandomPrioritizer.new
                     else
                       raise Puppet::DevError, "Unknown ordering type #{Puppet[:ordering]}"
                     end
  end

  def create_transaction(options)
    transaction = Puppet::Transaction.new(self, options[:report], prioritizer)
    transaction.tags = options[:tags] if options[:tags]
    transaction.ignoreschedules = true if options[:ignoreschedules]
    transaction.for_network_device = options[:network_device]

    transaction
  end

  # Verify that the given resource isn't declared elsewhere.
  def fail_on_duplicate_type_and_title(resource)
    # Short-circuit the common case,
    return unless existing_resource = @resource_table[title_key_for_ref(resource.ref)]

    # If we've gotten this far, it's a real conflict
    msg = "Duplicate declaration: #{resource.ref} is already declared"

    msg << " in file #{existing_resource.file}:#{existing_resource.line}" if existing_resource.file and existing_resource.line

    msg << "; cannot redeclare"

    raise DuplicateResourceError.new(msg, resource.file, resource.line)
  end

  # An abstracted method for converting one catalog into another type of catalog.
  # This pretty much just converts all of the resources from one class to another, using
  # a conversion method.
  def to_catalog(convert)
    result = self.class.new(self.name)

    result.version = self.version
    result.environment = self.environment

    map = {}
    resources.each do |resource|
      next if virtual_not_exported?(resource)
      next if block_given? and yield resource

      newres = resource.copy_as_resource
      newres.catalog = result

      if convert != :to_resource
        newres = newres.to_ral
      end

      # We can't guarantee that resources don't munge their names
      # (like files do with trailing slashes), so we have to keep track
      # of what a resource got converted to.
      map[resource.ref] = newres

      result.add_resource newres
    end

    message = convert.to_s.gsub "_", " "
    edges.each do |edge|
      # Skip edges between virtual resources.
      next if virtual_not_exported?(edge.source)
      next if block_given? and yield edge.source

      next if virtual_not_exported?(edge.target)
      next if block_given? and yield edge.target

      unless source = map[edge.source.ref]
        raise Puppet::DevError, "Could not find resource #{edge.source.ref} when converting #{message} resources"
      end

      unless target = map[edge.target.ref]
        raise Puppet::DevError, "Could not find resource #{edge.target.ref} when converting #{message} resources"
      end

      result.add_edge(source, target, edge.label)
    end

    map.clear

    result.add_class(*self.classes)
    result.tag(*self.tags)

    result
  end

  def virtual_not_exported?(resource)
    resource.respond_to?(:virtual?) and resource.virtual? and (resource.respond_to?(:exported?) and not resource.exported?)
  end
end
