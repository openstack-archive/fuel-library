require 'pathname'
require 'open3'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'corosync'
require 'rexml/document'

Puppet::Type.type(:cs_fencetopo).provide(:crm, :parent => Puppet::Provider::Corosync) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived. This provider will create or destroy
        a singleton for fencing topology configuration.'

  # Path to the crm binary for interacting with the cluster configuration.
  commands :crm           => 'crm'
  commands :cibadmin      => 'cibadmin'
  commands :crm_attribute => 'crm_attribute'

  def self.instances

    block_until_ready

    raw, status = dump_cib
    doc = REXML::Document.new(raw)
    nodes = []
    fence_topology = {}
    # return empty array, if there is no topology singleton configured in cib
    stanzas = doc.root.elements['configuration/fencing-topology'] rescue nil
    return [] if stanzas.nil?
    # otherwise, parse cib for existing topology singleton and return it as provider instance
    stanzas.each_element do |e|
      items = e.attributes
      line = { :fence_primitives => items['devices'], :node => items['target'], :index => items['index'] }
      primitives = line[:fence_primitives].split(',')
      if primitives.length > 1 then
        agents = []
        primitives.each { |primitive| agents << (/^stonith__([^__].+)__.*$/.match(primitive)[1] rescue 'primitive_name_parse_error') }
      else
        agents = [(/^stonith__([^__].+)__.*$/.match(primitives[0])[1] rescue 'primitive_name_parse_error')]
      end
      nodes.push(line[:node]) unless nodes.include?(line[:node])
      fence_topology[line[:node]] = {} if fence_topology[line[:node]].nil?
      fence_topology[line[:node]][line[:index]] = agents
    end
    property_instance = {
      :name       => 'myfencetopo',
      :ensure     => :present,
      :fence_topology      => fence_topology,
      :nodes      => nodes,
      :provider   => self.name
    }
    [new(property_instance)]
  end

  # SET
  def nodes=(should)
    @property_hash[:nodes] = should
  end

  def fence_topology=(should)
    @property_hash[:fence_topology] = should
  end
  #GET
  def nodes
    @property_hash[:nodes]
  end

  def fence_topology
    @property_hash[:fence_topology]
  end

  def create
    @property_hash = {
      :name   => @resource[:name],
      :ensure => :present,
      :fence_topology  => @resource[:fence_topology],
      :nodes => @resource[:nodes]
    }
    @property_hash[:cib] = @resource[:cib] if ! @resource[:cib].nil?
  end

  def destroy
    debug("Removing fencing topology")
    env = {}
    env["CIB_shadow"] = @resource[:cib].to_s if !@resource[:cib].nil?
    commands_to_exec = ''
    commands_to_exec << "#{command(:cibadmin)} --scope fencing-topology --delete-all --force --xpath //fencing-level 2>&1"
    commands_to_exec << "\n"
    commands_to_exec << "#{command(:cibadmin)} --delete --xml-text '<fencing-topology/>' 2>&1"
    exec_withenv(commands_to_exec, env)
    @property_hash.clear
  end

  def exists?
    self.class.block_until_ready
    debug(@property_hash.inspect)
    env = {}
    env["CIB_shadow"] = @resource[:cib].to_s if !@resource[:cib].nil?
    commands_to_exec = "#{command(:cibadmin)} --query --scope fencing-topology"
    exec_withenv(commands_to_exec, env) == 0
  end

  def flush
    unless @property_hash.empty? or self.class.instances != []
      self.class.block_until_ready
      args = ''
      @property_hash[:nodes].each do |node|
        # extract node's short name from its fqdn, if defined
        shortname = /^([^.]+)\..*$/.match(node)[1] rescue node
        pos = 1
        # start crafting node's topology from position #1,
        # nodes' topology lines should be separated by whitespace
        line = " #{node}: "
        @property_hash[:fence_topology][node].sort.each do |index, primitives|
           primitives.each do |primitive|
             line += case pos
               # first primitive should be put after its node fqdn
               when 1 then "stonith__#{primitive}__#{shortname}"
               # all primitives with the same indexes should be grouped together, coma separated
               when index then ",stonith__#{primitive}__#{shortname}"
               # all groups with different indexes should be separated by whitespace
               else " stonith__#{primitive}__#{shortname}"
             end
             pos = index if index != pos
           end
        end
        args += line
        # proceed to the next node
      end
      # send topology lines crafted for all nodes to crm
      env = {}
      env["CIB_shadow"] = @resource[:cib].to_s if !@resource[:cib].nil?
      command_to_exec = "#{command(:crm)} --force configure fencing_topology#{args} 2>&1"
      exec_withenv(command_to_exec, env)
    end
  end
end
