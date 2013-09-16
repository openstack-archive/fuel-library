Facter.add("osd_devices_list") do
    setcode do
        # Use any filesystem labeled "cephosd" as an osd
        devs = %x{blkid -o list | awk '{if ($3 == "cephosd") print $1}'}.split("\n")
        journal = %x{blkid -o list | awk '{if ($3 == "cephjournal") print $4}'}.strip

        devs.collect! do |d|
            if journal == ''
              d
            else
              part = d.split('/')[-1]
              "#{d}:#{journal}/#{part}-journal"
            end
        end
        devs.join(" ")
    end
end
