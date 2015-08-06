require 'puppet/ssl'

class Puppet::Indirector::SslFile < Puppet::Indirector::Terminus
  # Specify the directory in which multiple files are stored.
  def self.store_in(setting)
    @directory_setting = setting
  end

  # Specify a single file location for storing just one file.
  # This is used for things like the CRL.
  def self.store_at(setting)
    @file_setting = setting
  end

  # Specify where a specific ca file should be stored.
  def self.store_ca_at(setting)
    @ca_setting = setting
  end

  class << self
    attr_reader :directory_setting, :file_setting, :ca_setting
  end

  # The full path to where we should store our files.
  def self.collection_directory
    return nil unless directory_setting
    Puppet.settings[directory_setting]
  end

  # The full path to an individual file we would be managing.
  def self.file_location
    return nil unless file_setting
    Puppet.settings[file_setting]
  end

  # The full path to a ca file we would be managing.
  def self.ca_location
    return nil unless ca_setting
    Puppet.settings[ca_setting]
  end

  # We assume that all files named 'ca' are pointing to individual ca files,
  # rather than normal host files.  It's a bit hackish, but all the other
  # solutions seemed even more hackish.
  def ca?(name)
    name == Puppet::SSL::Host.ca_name
  end

  def initialize
    Puppet.settings.use(:main, :ssl)

    (collection_directory || file_location) or raise Puppet::DevError, "No file or directory setting provided; terminus #{self.class.name} cannot function"
  end

  def path(name)
    if name =~ Puppet::Indirector::BadNameRegexp then
      Puppet.crit("directory traversal detected in #{self.class}: #{name.inspect}")
      raise ArgumentError, "invalid key"
    end

    if ca?(name) and ca_location
      ca_location
    elsif collection_directory
      File.join(collection_directory, name.to_s + ".pem")
    else
      file_location
    end
  end

  # Remove our file.
  def destroy(request)
    path = path(request.key)
    return false unless Puppet::FileSystem::File.exist?(path)

    Puppet.notice "Removing file #{model} #{request.key} at '#{path}'"
    begin
      Puppet::FileSystem::File.unlink(path)
    rescue => detail
      raise Puppet::Error, "Could not remove #{request.key}: #{detail}"
    end
  end

  # Find the file on disk, returning an instance of the model.
  def find(request)
    filename = rename_files_with_uppercase(path(request.key))

    filename ? create_model(request.key, filename) : nil
  end

  # Save our file to disk.
  def save(request)
    path = path(request.key)
    dir = File.dirname(path)

    raise Puppet::Error.new("Cannot save #{request.key}; parent directory #{dir} does not exist") unless FileTest.directory?(dir)
    raise Puppet::Error.new("Cannot save #{request.key}; parent directory #{dir} is not writable") unless FileTest.writable?(dir)

    write(request.key, path) { |f| f.print request.instance.to_s }
  end

  # Search for more than one file.  At this point, it just returns
  # an instance for every file in the directory.
  def search(request)
    dir = collection_directory
    Dir.entries(dir).
      select  { |file| file =~ /\.pem$/ }.
      collect { |file| create_model(file.sub(/\.pem$/, ''), File.join(dir, file)) }.
      compact
  end

  private

  def create_model(name, path)
    result = model.new(name)
    result.read(path)
    result
  end

  # Demeterish pointers to class info.
  def collection_directory
    self.class.collection_directory
  end

  def file_location
    self.class.file_location
  end

  def ca_location
    self.class.ca_location
  end

  # A hack method to deal with files that exist with a different case.
  # Just renames it; doesn't read it in or anything.
  # LAK:NOTE This is a copy of the method in sslcertificates/support.rb,
  # which we'll be EOL'ing at some point.  This method was added at 20080702
  # and should be removed at some point.
  def rename_files_with_uppercase(file)
    return file if Puppet::FileSystem::File.exist?(file)

    dir, short = File.split(file)
    return nil unless Puppet::FileSystem::File.exist?(dir)

    raise ArgumentError, "Tried to fix SSL files to a file containing uppercase" unless short.downcase == short
    real_file = Dir.entries(dir).reject { |f| f =~ /^\./ }.find do |other|
      other.downcase == short
    end

    return nil unless real_file

    full_file = File.join(dir, real_file)

    Puppet.deprecation_warning "Automatic downcasing and renaming of ssl files is deprecated; please request the file using its correct case: #{full_file}"
    File.rename(full_file, file)

    file
  end

  # Yield a filehandle set up appropriately, either with our settings doing
  # the work or opening a filehandle manually.
  def write(name, path)
    if ca?(name) and ca_location
      Puppet.settings.setting(self.class.ca_setting).open('w') { |f| yield f }
    elsif file_location
      Puppet.settings.setting(self.class.file_setting).open('w') { |f| yield f }
    elsif setting = self.class.directory_setting
      begin
        Puppet.settings.setting(setting).open_file(path, 'w') { |f| yield f }
      rescue => detail
        raise Puppet::Error, "Could not write #{path} to #{setting}: #{detail}"
      end
    else
      raise Puppet::DevError, "You must provide a setting to determine where the files are stored"
    end
  end
end

# LAK:NOTE This has to be at the end, because classes like SSL::Key use this
# class, and this require statement loads those, which results in a load loop
# and lots of failures.
require 'puppet/ssl/host'
