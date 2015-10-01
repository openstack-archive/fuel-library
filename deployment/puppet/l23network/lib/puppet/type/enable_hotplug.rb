Puppet::Type.newtype(:enable_hotplug) do
    @doc = "Enables the network interface hotplug."
    desc @doc

    ensurable

    newparam(:name)


end
# vim: set ts=2 sw=2 et :
