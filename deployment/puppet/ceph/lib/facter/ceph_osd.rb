Facter.add("osd_devices_list") do
    setcode do
        # Use any filesystem labled "ceph" as an osd
        %x{blkid -o list | awk '{if ($3 == "ceph") print $1}'}
    end
end
