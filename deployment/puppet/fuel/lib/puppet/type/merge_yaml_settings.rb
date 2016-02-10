Puppet::Type.newtype(:merge_yaml_settings) do

    desc = "Type to merge yaml configuration files"

    ensurable

    newparam(:name) do
        desc "Path for destination settings file"
    end

    newparam(:sample_settings) do
        desc "Path or Hash containing source settings"
    end

    newparam(:override_settings) do
        desc "Path or Hash containing custom settings"
    end

end
