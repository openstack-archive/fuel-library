require 'puppet/util/filetype'

# Forward declaration
module PuppetX; end

module PuppetX::FileMapper

  # Copy all desired resource properties into this resource for generation upon flush
  #
  # This method is necessary for the provider to be ensurable
  def create
    raise Puppet::Error, "#{self.class} is in an error state" if self.class.failed?
    @resource.class.validproperties.each do |property|
      if value = @resource.should(property)
        @property_hash[property] = value
      end
    end

    self.dirty!
  end

  # Use the prefetched status to determine of the resource exists.
  #
  # This method is necessary for the provider to be ensurable
  #
  # @return [TrueClass || FalseClass]
  def exists?
    @property_hash[:ensure] and @property_hash[:ensure] == :present
  end

  # Update the property hash to mark this resource as absent for flushing
  #
  # This method is necessary for the provider to be ensurable
  def destroy
    @property_hash[:ensure] = :absent
    self.dirty!
  end

  # Mark the file associated with this resource as dirty
  def dirty!
    file = select_file
    self.class.dirty_file! file
  end


  # When processing on this resource is complete, trigger a flush on the file
  # that this resource belongs to.
  def flush
    self.class.flush_file(self.select_file)
  end

  def self.included(klass)
    klass.extend PuppetX::FileMapper::ClassMethods
    klass.mk_property_methods
    klass.initvars
  end

  module ClassMethods

    # @!attribute [rw] unlink_empty_files
    #   @return [TrueClass || FalseClass] Whether empty files will be removed
    attr_accessor :unlink_empty_files

    # @!attribute [rw] filetype
    #   @return [Symbol] The FileType to use when interacting with target files
    attr_accessor :filetype

    # @!attribute [r] mapped_files
    #   @return [Hash<filepath => Hash<:dirty => Bool, :filetype => Filetype>>]
    #     A data structure representing the file paths and filetypes backing this
    #     provider.
    attr_reader :mapped_files

    def initvars
      super
      @mapped_files = Hash.new {|h, k| h[k] = {}}
      @unlink_empty_files = false
      @filetype = :flat
      @failed = false
      @all_providers = []
    end

    def failed?
      @failed
    end

    def failed!
      @failed = true
    end

    # Register all provider instances with the class
    #
    # In order to flush all provider instances to a given file, we need to be
    # able to track them all. When provider#flush is called and the file
    # associated with that provider instance is dirty, the file needs to be
    # flushed and all provider instances associated with that file will be
    # passed to self.flush_file
    def new(*args)
      obj = super
      @all_providers << obj
      obj
    end

    # Returns all instances of the provider using this mixin.
    #
    # @return [Array<Puppet::Provider>]
    def instances
      provider_hashes = load_all_providers_from_disk

      provider_hashes.map do |h|
        h.merge!({:provider => self.name, :ensure => :present})
        new(h)
      end

    rescue
      # If something failed while loading instances, mark the provider class
      # as failed and pass the exception along
      @failed = true
      raise
    end

    # Validate that the required methods are available.
    #
    # @raise Puppet::DevError if an expected method is unavailable
    def validate_class!
      required_class_hooks    = [:target_files, :parse_file, :format_file]
      required_instance_hooks = [:select_file]

      required_class_hooks.each do |method|
        raise Puppet::DevError, "#{self} has not implemented `self.#{method}`" unless self.respond_to? method
      end

      required_instance_hooks.each do |method|
        raise Puppet::DevError, "#{self} has not implemented `##{method}`" unless self.method_defined? method
      end
    end

    # Reads all files from disk and returns an array of hashes representing
    # provider instances.
    #
    # @return [Array<Hash<String, Hash<Symbol, Object>>>]
    #   An array containing a set of hashes, keyed with a file path and values
    #   being a hash containg the state of the file and the filetype associated
    #   with it.
    #
    # @example
    #   IncludingProvider.load_all_providers_from_disk
    #   # => [
    #   #   { "/path/to/file" => {
    #   #     :dirty    => false,
    #   #     :filetype => #<Puppet::Util::FileTypeFlat:0x007fbf5b05ff10>,
    #   #   },
    #   #   { "/path/to/another/file" => {
    #   #     :dirty    => false,
    #   #     :filetype => #<Puppet::Util::FileTypeFlat:0x007fbf5b05c108,
    #   #   },
    #   #
    #
    def load_all_providers_from_disk
      validate_class!

      # Retrieve a list of files to fetch, and cache a copy of a filetype
      # for each one
      target_files.each do |file|
        @mapped_files[file][:filetype] = Puppet::Util::FileType.filetype(self.filetype).new(file)
        @mapped_files[file][:dirty]    = false
      end

      # Read and parse each file.
      provider_hashes = []
      @mapped_files.each_pair do |filename, file_attrs|
        arr = parse_file(filename, file_attrs[:filetype].read)
        unless arr.is_a? Array
          raise Puppet::DevError, "expected #{self}.parse_file to return an Array, got a #{arr.class}"
        end
        provider_hashes.concat arr
      end

      provider_hashes
    end

    # Match up all resources that have existing providers.
    #
    # Pass over all provider instances, and see if there is a resource with the
    # same namevar as a provider instance. If such a resource exists, set the
    # provider field of that resource to the existing provider.
    #
    # This is a hook method that will be called by Puppet::Transaction#prefetch
    #
    # @param [Hash<String, Puppet::Resource>] resources
    def prefetch(resources = {})

      # generate hash of {provider_name => provider}
      providers = instances.inject({}) do |hash, instance|
        hash[instance.name] = instance
        hash
      end

      # For each prefetched resource, try to match it to a provider
      resources.each_pair do |resource_name, resource|
        if provider = providers[resource_name]
          resource.provider = provider
        end
      end
    end

    # Create attr_accessors for properties and mark the provider as dirty on change.
    def mk_property_methods
      resource_type.validproperties.each do |attr|
        attr = attr.intern if attr.respond_to? :intern and not attr.is_a? Symbol

        # Generate the attr_reader method
        define_method(attr) do
          if @property_hash[attr].nil?
            :absent
          else
            @property_hash[attr]
          end
        end

        # Generate the attr_writer and have it mark the resource as dirty when called
        define_method("#{attr}=") do |val|
          @property_hash[attr] = val
          self.dirty!
        end
      end
    end

    # Generate an array of providers that should be flushed to a specific file
    #
    # Only providers that should be present will be returned regardless of
    # the containing file.
    #
    # @param [String] filename The name of the file to find providers for
    #
    # @return [Array<Puppet::Provider>]
    def collect_providers_for_file(filename)
      @all_providers.select do |provider|
        provider.select_file == filename and provider.ensure == :present
      end
    end

    def dirty_file!(filename)
      @mapped_files[filename][:dirty] = true
    end

    # Flush provider instances associated with the given file and call any defined hooks
    #
    # If the provider is in a failure state, the provider class will refuse to
    # flush any file, since we're in an unknown state.
    #
    # This method respects two method hooks: `pre_flush_hook` and `post_flush_hook`.
    # These methods must accept one argument, the path of the file being flushed.
    # `post_flush_hook` is guaranteed to be called after the flush has occurred.
    #
    # @param [String] filename The path of the file to be flushed
    def flush_file(filename)
      if failed?
        err "#{self.name} is in an error state, refusing to flush file #{filename}"
        return
      end

      if not @mapped_files[filename][:dirty]
        Puppet.debug "#{self.name} was requested to flush the file #{filename}, but it was not marked as dirty - doing nothing."
      else
        # Collect all providers that should be present and pass them to the
        # including class for formatting.
        target_providers = collect_providers_for_file(filename)
        file_contents = self.format_file(filename, target_providers)

        unless file_contents.is_a? String
          raise Puppet::DevError, "expected #{self}.format_file to return a String, got a #{file_contents.class}"
        end

        # Call the `pre_flush_hook` method if it's defined
        pre_flush_hook(filename) if self.respond_to? :pre_flush_hook

        begin
          if file_contents.empty? and self.unlink_empty_files
            remove_empty_file(filename)
          else
            perform_write(filename, file_contents)
          end
        ensure
          post_flush_hook(filename) if self.respond_to? :post_flush_hook
        end
      end
    rescue
      # If something failed during the flush process, mark the provider as
      # failed. There's not much we can do about any file that's already been
      # flushed but we can stop smashing things.
      @failed = true
      raise
    end

    # We have a dirty file and the new contents ready, back up the file and perform the flush.
    #
    # @param [String] filename The destination filename
    # @param [String] contents The new file contents
    def perform_write(filename, contents)
      @mapped_files[filename][:filetype] ||= Puppet::Util::FileType.filetype(self.filetype).new(filename)
      filetype = @mapped_files[filename][:filetype]

      filetype.backup if filetype.respond_to? :backup
      filetype.write(contents)
    end

    # Back up and remove a file, if it exists
    #
    # @param [String] filename The file to remove
    def remove_empty_file(filename)
      if File.exist? filename
        @mapped_files[filename][:filetype] ||= Puppet::Util::FileType.filetype(self.filetype).new(filename)
        filetype = @mapped_files[filename][:filetype]

        filetype.backup if filetype.respond_to? :backup

        File.unlink(filename)
      end
    end
  end
end
