require 'time'
require 'yaml'
require 'fileutils'
require 'facter'

# this library can be used by a custom fact to add caching feature

class FacterCache

  def initialize(name, ttl=3600, cache_dir='/etc/puppet/facts.d')
    @name = name.to_s
    @ttl = ttl.to_i
    @cache_dir = cache_dir.to_s
    raise ArgumentError, 'No fact name!' unless name and name.length > 0
    raise ArgumentError, 'No ttl!' unless ttl and ttl > 0
    raise ArgumentError, 'No cache_dir!' unless cache_dir and cache_dir.length > 0
  end

  attr_reader :name, :ttl, :cache_dir

  def fact_file
    File.join cache_dir, "cache_#{name}.yaml"
  end

  def fact_file_exists?
    File.exists? fact_file
  end

  def fact_file_mtime
    return @fact_file_mtime if @fact_file_mtime
    return unless fact_file_exists?
    @fact_file_mtime = File.mtime fact_file
  end

  def current_time
    Time.now
  end

  def still_cached?
    fact_file_mtime and (current_time - fact_file_mtime) < ttl
  end

  def cached_value
    return @cached_value if @cached_value
    data = YAML.load_file fact_file rescue {}
    @cached_value = data[name]
  end

  def write_fact_value(value)
    Facter.debug "Write fact '#{name}' value: #{value.inspect}"
    File.open fact_file, 'w' do |file|
      file.puts YAML.dump(name => value)
    end
  end

  def ensure_facts_directory
    FileUtils.mkdir_p cache_dir unless File.directory? cache_dir
  end

  def value
    ensure_facts_directory
    if still_cached? and cached_value
      Facter.debug "Read fact '#{name}' value: #{cached_value.inspect}"
      return cached_value
    end
    value = yield
    Facter.debug "Got fact '#{name}' value: #{value.inspect}"
    write_fact_value value
    value
  end

end
