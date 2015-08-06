require 'pathname'
require 'puppet/file_bucket'
require 'puppet/file_bucket/file'
require 'puppet/indirector/request'

class Puppet::FileBucket::Dipper
  # This is a transitional implementation that uses REST
  # to access remote filebucket files.

  attr_accessor :name

  # Create our bucket client
  def initialize(hash = {})
    # Emulate the XMLRPC client
    server      = hash[:Server]
    port        = hash[:Port] || Puppet[:masterport]
    environment = Puppet[:environment]

    if hash.include?(:Path)
      @local_path = hash[:Path]
      @rest_path  = nil
    else
      @local_path = nil
      @rest_path = "https://#{server}:#{port}/#{environment}/file_bucket_file/"
    end
  end

  def local?
    !! @local_path
  end

  # Back up a file to our bucket
  def backup(file)
    file_handle = Puppet::FileSystem::File.new(file)
    raise(ArgumentError, "File #{file} does not exist") unless file_handle.exist?
    contents = file_handle.binread
    begin
      file_bucket_file = Puppet::FileBucket::File.new(contents, :bucket_path => @local_path)
      files_original_path = absolutize_path(file)
      dest_path = "#{@rest_path}#{file_bucket_file.name}/#{files_original_path}"
      file_bucket_path = "#{@rest_path}#{file_bucket_file.checksum_type}/#{file_bucket_file.checksum_data}/#{files_original_path}"

      # Make a HEAD request for the file so that we don't waste time
      # uploading it if it already exists in the bucket.
      unless Puppet::FileBucket::File.indirection.head(file_bucket_path)
        Puppet::FileBucket::File.indirection.save(file_bucket_file, dest_path)
      end

      return file_bucket_file.checksum_data
    rescue => detail
      message = "Could not back up #{file}: #{detail}"
      Puppet.log_exception(detail, message)
      raise Puppet::Error, message
    end
  end

  # Retrieve a file by sum.
  def getfile(sum)
    source_path = "#{@rest_path}md5/#{sum}"
    file_bucket_file = Puppet::FileBucket::File.indirection.find(source_path, :bucket_path => @local_path)

    raise Puppet::Error, "File not found" unless file_bucket_file
    file_bucket_file.to_s
  end

  # Restore the file
  def restore(file,sum)
    restore = true
    file_handle = Puppet::FileSystem::File.new(file)
    if file_handle.exist?
      cursum = Digest::MD5.hexdigest(file_handle.binread)

      # if the checksum has changed...
      # this might be extra effort
      if cursum == sum
        restore = false
      end
    end

    if restore
      if newcontents = getfile(sum)
        newsum = Digest::MD5.hexdigest(newcontents)
        changed = nil
        if file_handle.exist? and ! file_handle.writable?
          changed = Puppet::FileSystem::File.new(file).stat.mode
          ::File.chmod(changed | 0200, file)
        end
        ::File.open(file, ::File::WRONLY|::File::TRUNC|::File::CREAT) { |of|
          of.binmode
          of.print(newcontents)
        }
        ::File.chmod(changed, file) if changed
      else
        Puppet.err "Could not find file with checksum #{sum}"
        return nil
      end
      return newsum
    else
      return nil
    end
  end

  private
  def absolutize_path( path )
    Pathname.new(path).realpath
  end

end

