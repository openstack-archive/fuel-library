Facter.add("osd_devices_list") do
    setcode do
        # Use any filesystem labeled "cephosd" as an osd
        devs = %x{blkid -o list | awk '{if ($3 == "cephosd") print $1}'}.split("\n")
        journal = %x{blkid -o list | awk '{if ($3 == "cephjournal") print $1}'}.split("\n")
        output = []

        if journal.length > 0
          ratio = (devs.length * 1.0 / journal.length).ceil
          ratio = ratio > 1 ? ratio : 1
          devs.each_slice(ratio) { |s|
            j = journal.shift
            output << s.map{|d| "#{d}:#{j}"}
          }
        else
            output = devs
        end
        output.join(" ")
    end
end
