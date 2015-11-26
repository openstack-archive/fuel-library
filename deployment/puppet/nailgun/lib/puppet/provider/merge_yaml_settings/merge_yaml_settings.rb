require 'yaml'

Puppet::Type.type(:merge_yaml_settings).provide(:ruby) do
    desc "Support for merging yaml configuration files."

    def create
        merged_settings = get_merged_settings
        File.open(@resource[:name], "w") { |f| f.puts merged_settings.to_yaml }
    end

    def destroy
        File.unlink(@resource[:name])
    end

    def exists?
        get_dict(@resource[:sample_settings]) == get_merged_settings
    end

    def get_merged_settings
        sample_settings = get_dict(@resource[:sample_settings])
        override_settings = get_dict(@resource[:override_settings])
        sample_settings.merge(override_settings)
    end

    def get_dict(obj)
        return obj if obj.is_a?(Hash)
        YAML.load_file(obj)
    end

    private :get_merged_settings, :get_dict

end
