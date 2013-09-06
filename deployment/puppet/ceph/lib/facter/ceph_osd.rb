Facter.add("osd_devices_list") do
    setcode do
        # Use any filesystem labeled "cephosd" as an osd
        %x{blkid -o list | awk '{if ($3 == "cephosd") print $1}'}
    end
end
