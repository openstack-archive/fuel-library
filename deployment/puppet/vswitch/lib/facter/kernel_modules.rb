# Fact: kmod_*
#
# Purpose: Provide facts about loaded and configured modules
#
# Resolution:
#
# Caveats:
require "set"

def get_modules
    return File.readlines("/proc/modules").inject(Set.new){|s,l|s << l[/\w+\b/]}
end

Facter.add("kernel_modules") do
    # confine :exists => "/proc/modules"
    confine :kernel => :linux
    setcode do
        modules = get_modules
        modules.to_a.join(",")
    end
end
