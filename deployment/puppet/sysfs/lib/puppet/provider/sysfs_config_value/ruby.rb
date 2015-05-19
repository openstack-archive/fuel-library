require 'fileutils'
require 'digest/md5'

Puppet::Type.type(:sysfs_config_value).provide(:ruby) do

  def glob(path)
    Dir.glob path
  end

  def included_sysfs_nodes
    return @included_sysfs_nodes if @included_sysfs_nodes
    return [] unless @resource[:sysfs]
    @included_sysfs_nodes = []
    return @included_sysfs_nodes unless @resource[:sysfs]
    @resource[:sysfs].each do |path|
      @included_sysfs_nodes += glob path
    end
    @included_sysfs_nodes
  end

  def excluded_sysfs_nodes
    return @excluded_sysfs_nodes if @excluded_sysfs_nodes
    return [] unless @resource[:exclude]
    @excluded_sysfs_nodes = []
    return @excluded_sysfs_nodes unless @resource[:exclude]
    @resource[:exclude].each do |path|
      @excluded_sysfs_nodes += glob path
    end
    @excluded_sysfs_nodes
  end

  def sysfs_nodes
    return @sysfs_nodes if @sysfs_nodes
    @sysfs_nodes = included_sysfs_nodes.reject do |included_node|
      excluded_sysfs_nodes.find do |excluded_node|
        included_node.start_with? excluded_node
      end
    end
  end

  def sysfs_node_value(node)
    value = @resource[:value]
    if @resource[:value].is_a? Hash
      value = @resource[:value].fetch 'default', nil
      @resource[:value].each do |override_node, override_value|
        if node.include? override_node
          value = override_value
          break
        end
      end
    end
    value
  end

  def generate_file_content
    return unless @resource.generate_content?
    content = ''
    sysfs_nodes.each do |node|
      node = node.gsub %r(^/sys/), ''
      content += "#{node} = #{sysfs_node_value node}\n"
    end
    debug 'Generated config content'
    @resource[:content] = content
  end

  def reset
    @included_sysfs_nodes = nil
    @excluded_sysfs_nodes = nil
    @sysfs_nodes = nil
  end

  ######################################################

  def file_name
    @resource[:name]
  end

  def file_base_dir
    File.dirname file_name
  end

  def file_mkdir
    FileUtils.mkdir_p file_base_dir unless File.directory? file_base_dir
    fail "Could not create the base directory for file: '#{file_name}'" unless File.directory? file_base_dir
  end

  def file_write(value)
    File.open(file_name, 'w') do |f|
      f.write value
    end
    fail "Error writing file: '#{file_name}'!" unless file_read == value
  end

  def file_exists?
    File.file? file_name
  end

  def file_remove
    File.delete file_name if file_exists?
  end

  def file_read
    return unless file_exists?
    File.read file_name
  end

  ######################################################

  def exists?
    debug 'Call: exists?'
    generate_file_content
    out = file_exists?
    debug "Return: '#{out}'"
    out
  end

  def create
    debug 'Call: create'
    file_mkdir
    file_write @resource[:content]
  end

  def destroy
    debug 'Call: destroy'
    file_remove
  end

  def content
    debug 'Call: content'
    out = file_read
    debug "Return: '(md5)#{Digest::MD5.hexdigest out}'"
    out
  end

  def content=(value)
    debug "Call: content='(md5)#{Digest::MD5.hexdigest value}'"
    file_write value
  end

end
