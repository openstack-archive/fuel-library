require 'find'
require 'forwardable'
require 'puppet/node/environment'
require 'puppet/parser/parser_factory'

class Puppet::Parser::TypeLoader
  extend  Forwardable
  include Puppet::Node::Environment::Helper

  # Import manifest files that match a given file glob pattern.
  #
  # @param pattern [String] the file glob to apply when determining which files
  #   to load
  # @param dir [String] base directory to use when the file is not
  #   found in a module
  # @api private
  def import(pattern, dir)
    return if Puppet[:ignoreimport]

    modname, files = Puppet::Parser::Files.find_manifests_in_modules(pattern, environment)
    if files.empty?
      abspat = File.expand_path(pattern, dir)
      file_pattern = abspat + (File.extname(abspat).empty? ? '{.pp,.rb}' : '' )

      files = Dir.glob(file_pattern).uniq.reject { |f| FileTest.directory?(f) }
      modname = nil

      if files.empty?
        raise_no_files_found(pattern)
      end
    end

    load_files(modname, files)
  end

  # Load all of the manifest files in all known modules.
  # @api private
  def import_all
    # And then load all files from each module, but (relying on system
    # behavior) only load files from the first module of a given name.  E.g.,
    # given first/foo and second/foo, only files from first/foo will be loaded.
    environment.modules.each do |mod|
      load_files(mod.name, mod.all_manifests)
    end
  end

  def_delegator :environment, :known_resource_types

  def initialize(env)
    self.environment = env
  end

  # Try to load the object with the given fully qualified name.
  def try_load_fqname(type, fqname)
    return nil if fqname == "" # special-case main.
    files_to_try_for(fqname).each do |filename|
      begin
        imported_types = import_from_modules(filename)
        if result = imported_types.find { |t| t.type == type and t.name == fqname }
          Puppet.debug "Automatically imported #{fqname} from #{filename} into #{environment}"
          return result
        end
      rescue Puppet::ImportError => detail
        # I'm not convienced we should just drop these errors, but this
        # preserves existing behaviours.
      end
    end
    # Nothing found.
    return nil
  end

  def parse_file(file)
    Puppet.debug("importing '#{file}' in environment #{environment}")
    parser = Puppet::Parser::ParserFactory.parser(environment)
    parser.file = file
    return parser.parse
  end

  private

  def import_from_modules(pattern)
    modname, files = Puppet::Parser::Files.find_manifests_in_modules(pattern, environment)
    if files.empty?
      raise_no_files_found(pattern)
    end

    load_files(modname, files)
  end

  def raise_no_files_found(pattern)
    raise Puppet::ImportError, "No file(s) found for import of '#{pattern}'"
  end

  def load_files(modname, files)
    @loaded ||= {}
    loaded_asts = []
    files.reject { |file| @loaded[file] }.each do |file|
      # NOTE: This ugly implementation will be replaced in Puppet 3.5.
      # The implementation now makes use of a global variable because the context support is
      # not available until Puppet 3.5.
      # The use case is that parsing for the purpose of searching for information
      # should not abort. There is currently one such use case in indirector/resourcetype/parser
      #
      if $squelsh_parse_errors
        begin
          loaded_asts << parse_file(file)
        rescue => e
          # Resume from errors so that all parseable files would
          # still be parsed. Mark this file as loaded so that
          # it would not be parsed next time (handle it as if
          # it was successfully parsed).
          Puppet.debug("Unable to parse '#{file}': #{e.message}")
        end
      else
        loaded_asts << parse_file(file)
      end

      @loaded[file] = true
    end

    loaded_asts.collect do |ast|
      known_resource_types.import_ast(ast, modname)
    end.flatten
  end

  # Return a list of all file basenames that should be tried in order
  # to load the object with the given fully qualified name.
  def files_to_try_for(qualified_name)
    qualified_name.split('::').inject([]) do |paths, name|
      add_path_for_name(paths, name)
    end
  end

  def add_path_for_name(paths, name)
    if paths.empty?
      [name]
    else
      paths.unshift(File.join(paths.first, name))
    end
  end
end
