Puppet::Type.newtype(:disable_hotplug) do
    @doc = "Disables the network interface hotplug."
    desc @doc

    ensurable

    newparam(:name)


end
# vim: set ts=2 sw=2 et :
