class Noop
  module Catalog
    # dumps the entire catalog structure to the text
    # representation in the Puppet language
    # @param context [Object] the context from the rspec test
    # @param resources_filter [Array] the list of resources to dump. Dump all resources if not given
    def dump_catalog(context, resources_filter = [])
      catalog = context.subject
      catalog = catalog.call if catalog.is_a? Proc
      text = ''
      resources_filter = [resources_filter] unless resources_filter.is_a? Array
      catalog.resources.select do |catalog_resource|
        if catalog_resource.type == 'Class'
          next false if %w(main Settings).include? catalog_resource.title.to_s
        end
        next true unless resources_filter.any?
        resources_filter.find do |filter_resource|
          resources_are_same? catalog_resource, filter_resource
        end
      end.sort_by do |catalog_resource|
        catalog_resource.to_s
      end.each do |catalog_resource|
        text += dump_resource(catalog_resource) + "\n"
        text += "\n"
      end
      text
    end

    # takes a parameter value and formats it to the literal value
    # that could be placed in the Puppet manifest
    # @param value [String, Array, Hash, true, false, nil]
    # @return [String]
    def parameter_value_format(value)
      case value
        when TrueClass then 'true'
        when FalseClass then 'false'
        when NilClass then 'undef'
        when Array then begin
          array = value.collect do |v|
            parameter_value_format v
          end.join(', ')
          "[ #{array} ]"
        end
        when Hash then begin
          hash = value.keys.sort do |a, b|
           a.to_s <=> b.to_s
          end.collect do |key|
           "#{parameter_value_format key.to_s} => #{parameter_value_format value[key]}"
          end.join(', ')
          "{ #{hash} }"
        end
        when Numeric, Symbol then parameter_value_format value.to_s
        when String then begin
          # escapes single quote characters and wrap into them
          "'#{value.gsub "'", '\\\\\''}'"
        end
        else value.to_s
      end
    end

    # take a resource object and generate a manifest representation of it
    # in the Puppet language. Replaces "to_manifest" Puppet function which
    # is not working correctly.
    # @param resource [Puppet::Resource]
    # @return [String]
    def dump_resource(resource)
      return '' unless resource.is_a? Puppet::Resource or resource.is_a? Puppet::Parser::Resource
      attributes = resource.keys
      if attributes.include?(:name) and resource[:name] == resource[:title]
        attributes.delete(:name)
      end
      attribute_max_length = attributes.inject(0) do |max_length, attribute|
        attribute.to_s.length > max_length ? attribute.to_s.length : max_length
      end
      attributes.sort!
      if attributes.first != :ensure && attributes.include?(:ensure)
        attributes.delete(:ensure)
        attributes.unshift(:ensure)
      end
      attributes_text_block = attributes.map { |attribute|
        value = resource[attribute]
        "  #{attribute.to_s.ljust attribute_max_length} => #{parameter_value_format value},\n"
      }.join
      "#{resource.type.to_s.downcase} { '#{resource.title.to_s}' :\n#{attributes_text_block}}"
    end

    # This function preprocesses both saved and generated
    # catalogs before they will be compared. It allows us to ignore
    # irrelevant changes in the catalogs:
    # * ignore trailing whitespaces
    # * ignore empty lines
    # @param data [String]
    # @return [String]
    def preprocess_catalog_data(data)
      clear_data = []
      data.to_s.split("\n").each do |line|
        line = line.rstrip
        next if line == ''
        clear_data << line
      end
      clear_data.join "\n"
    end

    # check if two resources have same type and title
    # @param res1 [Puppet::Resource]
    # @param res2 [Puppet::Resource]
    # @return [TrueClass, False,Class]
    def resources_are_same?(res1, res2)
      res1 = res1.to_s.downcase.gsub %r|'"|, ''
      res2 = res2.to_s.downcase.gsub %r|'"|, ''
      res1 == res2
    end

    # base directory of the catalog dump files
    # @return [String]
    def catalogs_dir
      return @catalogs_dir if @catalogs_dir
      @catalogs_dir = File.expand_path File.join(spec_dir, '..', '..', 'catalogs')
    end

    # base directory of the catalog dump file for this yaml
    # @return [String]
    def catalog_manifest_base_dir
      File.join catalogs_dir, astute_yaml_base
    end

    # full path to the catalog dump file
    # @param context [Object] the context from the rspec test
    # @return [String]
    def catalog_dump_file_path(context)
      manifest_name = manifest.gsub '/', '-'
      os = current_os context
      File.join catalog_manifest_base_dir, "#{manifest_name}-#{os}-catalog.pp.txt"
    end

    # save the catalog structure to the designated file as a text dump
    # @param context [Object] the context from the rspec test
    # @param resources_filter [Array] the list of resources to dump. Dump al lresources if not given
    def save_catalog_to_file(context, resources_filter)
      FileUtils.mkdir_p catalog_manifest_base_dir unless File.directory? catalog_manifest_base_dir
      file_path = catalog_dump_file_path(context)
      debug "Saving catalog to: '#{file_path}'"
      File.open(file_path, 'w') do |file|
        file.puts dump_catalog context, resources_filter
      end
    end

    # read the text dump of the catalog from the designated file
    # @param context [Object] the context from the rspec test
    def read_catalog_from_file(context)
      file_path = catalog_dump_file_path(context)
      return unless File.exists? file_path
      debug "Read catalog from: '#{file_path}'"
      File.read file_path
    end

  end
  extend Catalog
end
