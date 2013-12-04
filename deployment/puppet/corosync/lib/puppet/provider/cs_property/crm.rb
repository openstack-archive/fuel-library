require 'pathname' # JJM WORK_AROUND #14073
require 'open3'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'corosync'
require 'rexml/document'

include REXML

Puppet::Type.type(:cs_property).provide(:crm, :parent => Puppet::Provider::Corosync) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived. This provider will check the state
        of Corosync cluster configuration properties.'

  # Path to the crm binary for interacting with the cluster configuration.
  commands :crm           => 'crm'
  commands :cibadmin      => 'cibadmin'
  commands :crm_attribute => 'crm_attribute'
  def self.instances

    block_until_ready

    instances = []

    cmd = [ command(:crm), 'configure', 'show', 'xml' ]
    raw, status = dump_cib
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration/crm_config/cluster_property_set'].each_element do |e|
      items = e.attributes
      property = { :name => items['name'], :value => items['value'] }

      property_instance = {
        :name       => property[:name],
        :ensure     => :present,
        :value      => property[:value],
        :provider   => self.name
      }
      instances << new(property_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name   => @resource[:name],
      :ensure => :present,
      :value  => @resource[:value],
    }
    @property_hash[:cib] = @resource[:cib] if ! @resource[:cib].nil?
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Revmoving cluster property')
    cibadmin('--scope', 'crm_config', '--delete', '--xpath', "//nvpair[@name='#{resource[:name]}']")
    @property_hash.clear
  end

  # Getters that obtains the first and second primitives and score in our
  # ordering definintion that have been populated by prefetch or instances
  # (depends on if your using puppet resource or not).
  def value
    @property_hash[:value]
  end

  # Our setters for the first and second primitives and score.  Setters are
  # used when the resource already exists so we just update the current value
  # in the property hash and doing this marks it to be flushed.
  def value=(should)
    @property_hash[:value] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    unless @property_hash.empty?
      self.class.block_until_ready
      # clear this on properties, in case it's set from a previous
      # run of a different corosync type
      env = {}
      success = nil
      retries = @resource[:retries]
      env["CIB_shadow"] = @resource[:cib].to_s if !@resource[:cib].nil?
      command_to_exec="#{command(:crm)}  --force configure property \\$id=\"cib-bootstrap-options\" #{@property_hash[:name]}=#{@property_hash[:value]} 2>&1"
     while !success do
        retries -= 1
        raise(Puppet::Error,"unable to set cluster property") if retries < 0
        notice("will try to set cluster property value. #{retries} retries left")
        exec_withenv(command_to_exec, env)
        debug("Fetching cluster property value")
        result_command = ""
        result_command << "CIB_shadow = #{@resource[:cib]} " if !@resource[:cib].nil?
        result_command << "#{command(:cibadmin)} --scope crm_config -Q --xpath \"//nvpair[@name='#{resource[:name]}']\""
        debug("Executing #{result_command}")
        stdout = Open3.popen3(result_command)[1].read
        debug("Got #{stdout}")
        begin
                result_xml = REXML::Document.new(stdout)
        rescue
                #pass
        end
        if !result_xml.nil? and !result_xml.root.nil?
                debug("result_xml is #{result_xml.root.to_s}")
                success = result_xml.root.attributes['value'] == @resource[:value]
        end
        sleep 2
      end
    end
  end
end
