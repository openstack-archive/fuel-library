class Puppet::Provider::Corosync < Puppet::Provider
  require "open3"
  # Yep, that's right we are parsing XML...FUN! (It really wasn't that bad)
  require 'rexml/document'
  #require 'system'


  def self.dump_cib
    stdout = Open3.popen3("#{command(:crm)} configure show xml")[1].read
    return stdout, nil
  end

  def try_command(command,resource_name,should=nil,cib=nil,timeout=120)
    cmd = "#{command(:crm)} configure #{command} #{resource_name} #{should} ".rstrip
    env = {}
      if cib
        env["CIB_shadow"]=cib.to_s
      end
    Timeout::timeout(timeout) do
      debug("Issuing  #{cmd} for CIB #{cib}  ")
      loop do
        break  if exec_withenv(cmd,env) == 0
        sleep 2
      end
    end
  end

  def exec_withenv(cmd,env=nil)
    self.class.exec_withenv(cmd,env)
  end

  def self.exec_withenv(cmd,env=nil)
    Process.fork  do
      ENV.update(env) if !env.nil?
      Process.exec(cmd)
    end
    Process.wait
    $?.exitstatus
  end

  # Corosync takes a while to build the initial CIB configuration once the
  # service is started for the first time.  This provides us a way to wait
  # until we're up so we can make changes that don't disappear in to a black
  # hole.

  def self.block_until_ready(timeout = 120)
    cmd = "#{command(:crm_attribute)} --type crm_config --query --name dc-version 2>/dev/null"
    Timeout::timeout(timeout) do
      until exec_withenv(cmd) == 0
        debug('Corosync not ready, retrying')
        sleep 2
      end
      # Sleeping a spare two since it seems that dc-version is returning before
      # It is really ready to take config changes, but it is close enough.
      # Probably need to find a better way to check for reediness.
      sleep 2
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if res = resources[prov.name.to_s]
        res.provider = prov
      end
    end
  end

  def exists?
    self.class.block_until_ready
    debug(@property_hash.inspect)
    !(@property_hash[:ensure] == :absent or @property_hash.empty?)
  end

  def get_scope(type)
      case type
      when 'resource'
          scope='resources'
      when /^(colocation|order|location)$/
          scope='constraints'
      when 'rsc_defaults'
          scope='rsc_defaults'
      else
          fail('unknown resource type')
          scope=nil
      end
      return scope
  end

  def apply_changes(res_name,tmpfile,res_type)
      env={}
      shadow_name="#{res_type}_#{res_name}"
      original_cib="/tmp/#{shadow_name}_orig.xml"
      new_cib="/tmp/#{shadow_name}_new.xml"
      begin
        debug('trying to delete old shadow if exists')
        crm_shadow("-b","-f","-D",shadow_name)
      rescue Puppet::ExecutionFailure
        debug('delete failed but proceeding anyway')
      end
      crm_shadow("-b","-c",shadow_name)
      env["CIB_shadow"] = shadow_name
      exec_withenv("#{command(:crm)} configure load update #{tmpfile.path.to_s}",env)
      if !get_scope(res_type).nil?
          cibadmin_scope = "-o #{get_scope(res_type)}"
      else
          cibadmin_scope = nil
      end
      orig_status = exec_withenv("#{command(:cibadmin)} #{cibadmin_scope} -Q > /tmp/#{shadow_name}_orig.xml")
      #cibadmin returns code 6 if scope is empty
      #in this case write empty file
      if orig_status == 6 or File.open("/tmp/#{shadow_name}_orig.xml").read.empty?
          cur_scope=REXML::Element.new(get_scope(res_type)).to_s
          emptydoc=REXML::Document.new(cur_scope)
          emptydoc.write(File.new("/tmp/#{shadow_name}_orig.xml",'w'))
      end
      exec_withenv("#{command(:cibadmin)} #{cibadmin_scope} -Q > /tmp/#{shadow_name}_new.xml",env)
      patch = Open3.popen3("#{command(:crm_diff)} --original #{original_cib} --new #{new_cib}")[1].read
      if patch.empty?
          debug("no difference - nothing to apply")
          return
      end
      xml_patch = REXML::Document.new(patch)
      wrap_cib=REXML::Element.new('cib')
      wrap_configuration=REXML::Element.new('configuration')
      wrap_cib.add_element(wrap_configuration)
      wrap_cib_a=Marshal.load(Marshal.dump(wrap_cib))
      wrap_cib_r=Marshal.load(Marshal.dump(wrap_cib))
      diff_a=REXML::XPath.first(xml_patch,'//diff-added')
      diff_r=REXML::XPath.first(xml_patch,'//diff-removed')
      diff_a_elements=diff_a.elements
      diff_r_elements=diff_r.elements
      wrap_configuration_a=REXML::XPath.first(wrap_cib_a,'//configuration')
      wrap_configuration_r=REXML::XPath.first(wrap_cib_r,'//configuration')
      diff_a_elements.each {|element| wrap_configuration_a.add_element(element)}
      diff_r_elements.each {|element| wrap_configuration_r.add_element(element)}
      diff_a.add_element(wrap_cib_a)
      diff_r.add_element(wrap_cib_r)
      cibadmin '--patch', '--sync-call', '--xml-text', xml_patch
  end

end
