class Noop
  module Catalog
    def dump_catalog(context, resources = [])
      catalog = context.subject
      catalog = catalog.call if catalog.is_a? Proc
      text = ''
      resources = [resources] unless resources.is_a? Array
      catalog.resources.select do |catalog_resource|
        next true unless resources.any?
        resources.find do |filter_resource|
          resource_matcher catalog_resource, filter_resource
        end
      end.sort_by do |catalog_resource|
        catalog_resource.to_s
      end.each do |catalog_resource|
        text += catalog_resource.to_manifest + "\n"
        # TODO: do semething with present or missing "name" attribute with different puppet versions
        text += "\n"
      end
      text
    end

    def resource_matcher(res1, res2)
      res1 = res1.to_s.downcase.gsub %r|'"|, ''
      res2 = res2.to_s.downcase.gsub %r|'"|, ''
      res1 == res2
    end

    def catalogs_dir
      return @catalogs_dir if @catalogs_dir
      @catalogs_dir = File.expand_path File.join(spec_dir, '..', '..', 'catalogs')
    end

    def catalog_manifest_base_dir
      File.join catalogs_dir, astute_yaml_base
    end

    def catalog_dump_file_path(context)
      manifest_name = manifest.gsub '/', '-'
      os = current_os context
      File.join catalog_manifest_base_dir, "#{manifest_name}-#{os}-catalog.pp.txt"
    end

    def save_catalog_to_file(context, resources)
      FileUtils.mkdir_p catalog_manifest_base_dir unless File.directory? catalog_manifest_base_dir
      file_path = catalog_dump_file_path(context)
      debug "Saving catalog to: '#{file_path}'"
      File.open(file_path, 'w') do |file|
        file.puts dump_catalog context, resources
      end
    end

    def read_catalog_from_file(context)
      file_path = catalog_dump_file_path(context)
      return unless File.exists? file_path
      debug "Read catalog from: '#{file_path}'"
      File.read file_path
    end

  end
  extend Catalog
end
