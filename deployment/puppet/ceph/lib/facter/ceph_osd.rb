Facter.add("osd_devices_list") do
    setcode do
        devs = %x{lsblk -ln | awk '{if ($6 == "disk") print $1}'}.split("\n")
        output = []
        osds = []
        journals = []

        # Finds OSD and journal devices based on Partition GUID
        devs.each { |d|
            # lsblk returns cciss devices as cciss!c0d0p1. The entries
            # in /dev are cciss/c0d0p1
            d.gsub!(/!/, '/')
            parts = %x{ls /dev/#{d}?*}.gsub("/dev/#{d}","").split("\n")
            parts.each { |p|
                code = %x{sgdisk -i #{p} /dev/#{d} | grep "Partition GUID code" | awk '{print $4}'}.strip()
                case code
                when "4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D"
                    # Only use unmounted devices
                    if %x{grep -c /dev/#{d}#{p} /proc/mounts}.to_i == 0
                        osds << "/dev/#{d}#{p}"
                    end
                when "45B0969E-9B03-4F30-B4C6-B4B80CEFF106"
                    if %x{grep -c /dev/#{d}#{p} /proc/mounts}.to_i == 0
                        journals << "/dev/#{d}#{p}"
                    end
                end
            }
        }

        if journals.length > 0
          osds.each { |osd|
            journal = journals.shift
            if journal
              output << "#{osd}:#{journal}"
            else
              output << osd
            end
          }
        else
            output = osds
        end
        output.join(" ")
    end
end
