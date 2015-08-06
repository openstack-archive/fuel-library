require 'puppet/node'
require 'puppet/resource/catalog'
require 'puppet/indirector/code'
require 'puppet/util/profiler'
require 'yaml'

class Puppet::Resource::Catalog::Compiler < Puppet::Indirector::Code
  desc "Compiles catalogs on demand using Puppet's compiler."

  include Puppet::Util

  attr_accessor :code

  def extract_facts_from_request(request)
    return unless text_facts = request.options[:facts]
    unless format = request.options[:facts_format]
      raise ArgumentError, "Facts but no fact format provided for #{request.key}"
    end

    Puppet::Util::Profiler.profile("Found facts") do
      # If the facts were encoded as yaml, then the param reconstitution system
      # in Network::HTTP::Handler will automagically deserialize the value.
      if text_facts.is_a?(Puppet::Node::Facts)
        facts = text_facts
      else
        # We unescape here because the corrosponding code in Puppet::Configurer::FactHandler escapes
        facts = Puppet::Node::Facts.convert_from(format, CGI.unescape(text_facts))
      end

      unless facts.name == request.key
        raise Puppet::Error, "Catalog for #{request.key.inspect} was requested with fact definition for the wrong node (#{facts.name.inspect})."
      end

      facts.add_timestamp
      Puppet::Node::Facts.indirection.save(facts)
    end
  end

  # Compile a node's catalog.
  def find(request)
    extract_facts_from_request(request)

    node = node_from_request(request)
    node.trusted_data = trusted_hash_from_request(request)

    if catalog = compile(node)
      return catalog
    else
      # This shouldn't actually happen; we should either return
      # a config or raise an exception.
      return nil
    end
  end


  # filter-out a catalog to remove exported resources
  def filter(catalog)
    return catalog.filter { |r| r.virtual? } if catalog.respond_to?(:filter)
    catalog
  end

  def initialize
    Puppet::Util::Profiler.profile("Setup server facts for compiling") do
      set_server_facts
    end
  end

  # Is our compiler part of a network, or are we just local?
  def networked?
    Puppet.run_mode.master?
  end

  private

  # Produces a deeply frozen hash with trusted information
  # The key :authenticated is always present in the result with one of the values
  # :remote, :local, false, where :remote is authenticated via cert, :local is trusted by virtue
  # of running on the same machine (not a remove request), and false is an unauthenticated remot request.
  # When the trusted hash value for :authenticated == false, there is no other values set in the hash.
  #
  def trusted_hash_from_request(request)
    if request.remote?
      if request.authenticated?
        trust_authenticated = 'remote'.freeze
        client_cert = request.node
      else
        trust_authenticated = false
        client_cert = nil
      end
    else
      trust_authenticated = 'local'.freeze
      # Always trust local data by picking up the available parameters.
      request_node = request.options[:use_node]
      client_cert = request_node ? request_node.parameters['clientcert'] : nil
    end

    # TODO nil or undef for client_cert missing?
    trusted_hash = { 'authenticated' => trust_authenticated, 'certname' => client_cert }.freeze
  end

  # Add any extra data necessary to the node.
  def add_node_data(node)
    # Merge in our server-side facts, so they can be used during compilation.
    node.merge(@server_facts)
  end

  # Compile the actual catalog.
  def compile(node)
    str = "Compiled catalog for #{node.name}"
    str += " in environment #{node.environment}" if node.environment
    config = nil

    benchmark(:notice, str) do
      Puppet::Util::Profiler.profile(str) do
        begin
          config = Puppet::Parser::Compiler.compile(node)
        rescue Puppet::Error => detail
          Puppet.err(detail.to_s) if networked?
          raise
        end
      end
    end

    config
  end

  # Turn our host name into a node object.
  def find_node(name, environment)
    Puppet::Util::Profiler.profile("Found node information") do
      node = nil
      begin
        node = Puppet::Node.indirection.find(name, :environment => environment)
      rescue => detail
        message = "Failed when searching for node #{name}: #{detail}"
        Puppet.log_exception(detail, message)
        raise Puppet::Error, message
      end


      # Add any external data to the node.
      if node
        add_node_data(node)
      end
      node
    end
  end

  # Extract the node from the request, or use the request
  # to find the node.
  def node_from_request(request)
    if node = request.options[:use_node]
      if request.remote?
        raise Puppet::Error, "Invalid option use_node for a remote request"
      else
        return node
      end
    end

    # We rely on our authorization system to determine whether the connected
    # node is allowed to compile the catalog's node referenced by key.
    # By default the REST authorization system makes sure only the connected node
    # can compile his catalog.
    # This allows for instance monitoring systems or puppet-load to check several
    # node's catalog with only one certificate and a modification to auth.conf
    # If no key is provided we can only compile the currently connected node.
    name = request.key || request.node
    if node = find_node(name, request.environment)
      return node
    end

    raise ArgumentError, "Could not find node '#{name}'; cannot compile"
  end

  # Initialize our server fact hash; we add these to each client, and they
  # won't change while we're running, so it's safe to cache the values.
  def set_server_facts
    @server_facts = {}

    # Add our server version to the fact list
    @server_facts["serverversion"] = Puppet.version.to_s

    # And then add the server name and IP
    {"servername" => "fqdn",
      "serverip" => "ipaddress"
    }.each do |var, fact|
      if value = Facter.value(fact)
        @server_facts[var] = value
      else
        Puppet.warning "Could not retrieve fact #{fact}"
      end
    end

    if @server_facts["servername"].nil?
      host = Facter.value(:hostname)
      if domain = Facter.value(:domain)
        @server_facts["servername"] = [host, domain].join(".")
      else
        @server_facts["servername"] = host
      end
    end
  end
end
