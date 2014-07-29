require 'facter'

# gateway.rb 
Facter.add("gateway") do
    setcode do
        begin
            Facter.lsbdistid
        rescue
            Facter.loadfacts()
        end
        gateway = %x{/sbin/ip route | awk '/default/{ print $3 }'}.chomp
        gateway
    end
end
# end gateway.rb 
