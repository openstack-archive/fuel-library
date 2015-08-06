# An abstraction over the ruby file system operations for a single file.
#
# For the time being this is being kept private so that we can evolve it for a
# while.
#
# @api private
class Puppet::FileSystem::File
  attr_reader :path

  IMPL = if RUBY_VERSION =~ /^1\.8/
           require 'puppet/file_system/file18'
           Puppet::FileSystem::File18
         elsif Puppet::Util::Platform.windows?
           require 'puppet/file_system/file19windows'
           Puppet::FileSystem::File19Windows
         else
           require 'puppet/file_system/file19'
           Puppet::FileSystem::File19
         end

  @remembered = {}

  def self.new(path)
    if @remembered.include?(path.to_s)
      @remembered[path.to_s]
    else
      file = IMPL.allocate
      file.send(:initialize, path)
      file
    end
  end

  # Run a block of code with a file accessible in the filesystem.
  # @note This API should only be used for testing
  #
  # @param file [Object] an object that conforms to the Puppet::FileSystem::File interface
  # @api private
  def self.overlay(file, &block)
    remember(file)
    yield
  ensure
    forget(file)
  end

  # Create a binding between a filename and a particular instance of a file object.
  # @note This API should only be used for testing
  #
  # @param file [Object] an object that conforms to the Puppet::FileSystem::File interface
  # @api private
  def self.remember(file)
    @remembered[file.path.to_s] = file
  end

  # Forget a remembered file
  # @note This API should only be used for testing
  #
  # @param file [Object] an object that conforms to the Puppet::FileSystem::File interface
  # @api private
  def self.forget(file)
    @remembered.delete(file.path.to_s)
  end

  def initialize(path)
    if path.is_a?(Pathname)
      @path = path
    else
      @path = Pathname.new(path)
    end
  end

  def open(mode, options, &block)
    ::File.open(@path, options, mode, &block)
  end

  # @return [Puppet::FileSystem::File] The directory of this file
  # @api public
  def dir
    Puppet::FileSystem::File.new(@path.dirname)
  end

  # @return [String] the name of the file
  # @api public
  def basename
    @path.basename.to_s
  end

  # @return [Num] The size of this file
  # @api public
  def size
    @path.size
  end

  # Allows exclusive updates to a file to be made by excluding concurrent
  # access using flock. This means that if the file is on a filesystem that
  # does not support flock, this method will provide no protection.
  #
  # While polling to aquire the lock the process will wait ever increasing
  # amounts of time in order to prevent multiple processes from wasting
  # resources.
  #
  # @param mode [Integer] The mode to apply to the file if it is created
  # @param options [Integer] Extra file operation mode information to use
  # (defaults to read-only mode)
  # @param timeout [Integer] Number of seconds to wait for the lock (defaults to 300)
  # @yield The file handle, in read-write mode
  # @return [Void]
  # @raise [Timeout::Error] If the timeout is exceeded while waiting to aquire the lock
  # @api public
  def exclusive_open(mode, options = 'r', timeout = 300, &block)
    wait = 0.001 + (Kernel.rand / 1000)
    written = false
    while !written
      ::File.open(@path, options, mode) do |rf|
        if rf.flock(::File::LOCK_EX|::File::LOCK_NB)
          yield rf
          written = true
        else
          sleep wait
          timeout -= wait
          wait *= 2
          if timeout < 0
            raise Timeout::Error, "Timeout waiting for exclusive lock on #{@path}"
          end
        end
      end
    end
  end

  def each_line(&block)
    ::File.open(@path) do |f|
      f.each_line do |line|
        yield line
      end
    end
  end

  # @return [String] The contents of the file
  def read
    @path.read
  end

  # @return [String] The binary contents of the file
  def binread
    raise NotImplementedError
  end

  # Determine if a file exists by verifying that the file can be stat'd.
  # Will follow symlinks and verify that the actual target path exists.
  #
  # @return [Boolean] true if the named file exists.
  def self.exist?(path)
    return IMPL.exist?(path) if IMPL.method(:exist?) != self.method(:exist?)
    File.exist?(path)
  end

  # Determine if a file exists by verifying that the file can be stat'd.
  # Will follow symlinks and verify that the actual target path exists.
  #
  # @return [Boolean] true if the path of this file is present
  def exist?
    self.class.exist?(@path)
  end

  # Determine if a file is executable.
  #
  # @todo Should this take into account extensions on the windows platform?
  #
  # @return [Boolean] true if this file can be executed
  def executable?
    ::File.executable?(@path)
  end

  # @return [Boolean] Whether the file is writable by the current
  # process
  def writable?
    @path.writable?
  end

  # Touches the file. On most systems this updates the mtime of the file.
  def touch
    ::FileUtils.touch(@path)
  end

  # Create the entire path as directories
  def mkpath
    @path.mkpath
  end

  # Creates a symbolic link dest which points to the current file.
  # If dest already exists:
  #
  # * and is a file, will raise Errno::EEXIST
  # * and is a directory, will return 0 but perform no action
  # * and is a symlink referencing a file, will raise Errno::EEXIST
  # * and is a symlink referencing a directory, will return 0 but perform no action
  #
  # With the :force option set to true, when dest already exists:
  #
  # * and is a file, will replace the existing file with a symlink (DANGEROUS)
  # * and is a directory, will return 0 but perform no action
  # * and is a symlink referencing a file, will modify the existing symlink
  # * and is a symlink referencing a directory, will return 0 but perform no action
  #
  # @param dest [String] The path to create the new symlink at
  # @param [Hash] options the options to create the symlink with
  # @option options [Boolean] :force overwrite dest
  # @option options [Boolean] :noop do not perform the operation
  # @option options [Boolean] :verbose verbose output
  #
  # @raise [Errno::EEXIST] dest already exists as a file and, :force is not set
  #
  # @return [Integer] 0
  def symlink(dest, options = {})
    FileUtils.symlink(@path, dest, options)
  end

  # @return [Boolean] true if the file is a symbolic link.
  def symlink?
    File.symlink?(@path)
  end

  # @return [String] the name of the file referenced by the given link.
  def readlink
    File.readlink(@path)
  end

  # Deletes the named files, returning the number of names passed as arguments.
  # See also Dir::rmdir.
  #
  # @raise an exception on any error.
  #
  # @return [Integer] the number of names passed as arguments
  def self.unlink(*file_names)
    return IMPL.unlink(*file_names) if IMPL.method(:unlink) != self.method(:unlink)
    File.unlink(*file_names)
  end

  # Deletes the file.
  # See also Dir::rmdir.
  #
  # @raise an exception on any error.
  #
  # @return [Integer] the number of names passed as arguments, in this case 1
  def unlink
    self.class.unlink(@path)
  end

  # @return [File::Stat] object for the named file.
  def stat
    File.stat(@path)
  end

  # @return [File::Stat] Same as stat, but does not follow the last symbolic
  # link. Instead, reports on the link itself.
  def lstat
    File.lstat(@path)
  end

  # Compare the contents of this file against the contents of a stream.
  # @param stream [IO] The stream to compare the contents against
  # @return [Boolean] Whether the contents were the same
  def compare_stream(stream)
    open(0, 'rb') do |this|
      FileUtils.compare_stream(this, stream)
    end
  end

  def to_s
    @path.to_s
  end
end
