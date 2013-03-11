require 'pathname'
require Pathname.new(__FILE__).dirname.dirname.expand_path + 'corosync'

Puppet::Type.type(:cs_group).provide(:crm, :parent => Puppet::Provider::Corosync) do
  desc 'Provider to add, delete, manipulate primitive groups.'

  # Path to the crm binary for interacting with the cluster configuration.
  commands :crm => '/usr/sbin/crm'
  commands :crm_attribute => '/usr/sbin/crm_attribute'
  def self.instances

    block_until_ready

    instances = []

    #cmd = [ command(:crm), 'configure', 'show', 'xml' ]
    raw, status = dump_cib
    doc = REXML::Document.new(raw)

    REXML::XPath.each(doc, '//group') do |e|

      items = e.attributes
      group = { :name => items['id'] }

      primitives = []

      if ! e.elements['primitive'].nil?
        e.each_element do |p|
          primitives << p.attributes['id']
        end
      end

      group_instance = {
        :name       => group[:name],
        :ensure     => :present,
        :primitives => primitives,
        :provider   => self.name
      }
      instances << new(group_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name       => @resource[:name],
      :ensure     => :present,
      :primitives => @resource[:primitives]
    }
    @property_hash[:cib] = @resource[:cib] if ! @resource[:cib].nil?
  end

  # Unlike create we actually immediately delete the item but first, like primitives,
  # we need to stop the group.
  def destroy
    debug('Stopping group before removing it')
    crm('resource', 'stop', @resource[:name])
    debug('Revmoving group')
    crm('configure', 'delete', @resource[:name])
    @property_hash.clear
  end

  # Getter that obtains the primitives array for us that should have
  # been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def primitives
    @property_hash[:primitives]
  end

  # Our setters for the primitives array and score.  Setters are used when the
  # resource already exists so we just update the current value in the property
  # hash and doing this marks it to be flushed.
  def primitives=(should)
    @property_hash[:primitives] = should.sort
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    unless @property_hash.empty?
      self.class.block_until_ready
      updated = 'group '
      updated << "#{@property_hash[:name]} #{@property_hash[:primitives].join(' ')}"
      Tempfile.open('puppet_crm_update') do |tmpfile|
        tmpfile.write(updated.rstrip)
        tmpfile.flush
        env = {}
        env["CIB_shadow"] = @resource[:cib].to_s if !@resource[:cib].nil?
        exec_withenv("#{command(:crm)} configure load update #{tmpfile.path.to_s}",env)
      end
    end
  end
end
