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
            if d.gsub!(/!/, '/')
              sep = 'p'
            else
              sep = ''
            end
            device = "/dev/#{d}#{sep}"
            parts = %x{ls /dev/#{d}?*}.gsub(device,"").split("\n")
            parts.each { |p|
                code = %x{sgdisk -i #{p} /dev/#{d} | grep "Partition GUID code" | awk '{print $4}'}.strip()
                case code
                when "4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D"
                    # Only use unmounted devices
                    if %x{grep -c #{device}#{p} /proc/mounts}.to_i == 0
                        mp = %x{mktemp -d}.strip()
                        begin
                            mount_result = %x{mount #{device}#{p} #{mp} && test -f #{mp}/fsid && echo 0 || echo 1}.to_i
                        rescue
                        else
                            osds << ["#{device}#{p}", !mount_result.zero?]
                        ensure
                            %x{umount -f #{mp}}
                        end
                    end
                when "45B0969E-9B03-4F30-B4C6-B4B80CEFF106"
                    if %x{grep -c #{device}#{p} /proc/mounts}.to_i == 0
                        journals << "#{device}#{p}"
                    end
                end
            }
        }

        osds.each { |osd, prepare|
          journal = journals.shift
          if (not journal.nil?) && (not journal.empty?)
            devlink = %x{udevadm info -q property -n #{journal} | awk 'BEGIN {FS="="} {if ($1 == "DEVLINKS") print $2}'}
            devlink = devlink.split(' ')
            journal = (devlink.find { |s| s.include? 'by-id' } or journal)
            osd_disk = "#{osd}:#{journal}"
          else
            osd_disk = osd
          end
          if prepare == true
              osd_disk += "!new"
          end
          output << osd_disk
        }
        output.join(" ")
    end
end
