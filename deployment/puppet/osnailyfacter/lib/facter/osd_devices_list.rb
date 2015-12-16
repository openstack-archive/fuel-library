Facter.add("osd_devices_list") do
    setcode do
      output = []
      disks = {}
      osds = []
      journals = []
      devices = Facter::Util::Resolution.exec(%q{lsblk -nr -o KNAME,TYPE}).split("\n").map{|x| x.split}
      disk = ''
      devices.each { |x|
        if x[1] == "disk"
          # lsblk returns cciss devices as cciss!c0d0p1. The entries
          # in /dev are cciss/c0d0p1. ! is replaced with /
          disk = x[0].gsub(/!/, '/')
          disks[disk] = []
        elsif x[1] == "part"
          disks[disk] << x[0].gsub(/!/, '/')
        end
      }
      # Finds OSD and journal devices based on Partition GUID
      disks.each { |disk,parts|
        device = "/dev/#{disk}"
        parts.each { |p|
          pnum = p.gsub(/#{disk}p*/, '')
          code = Facter::Util::Resolution.exec(%Q{sgdisk -i #{pnum} #{device}}).match(/Partition GUID code:\s+(\S+)\s/)[1]

          case code
          when "4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D"
            # Only use unmounted devices
            if Facter::Util::Resolution.exec(%Q{grep -c /dev/#{p} /proc/mounts}).to_i == 0
              osds << "/dev/#{p}"
            end
          when "45B0969E-9B03-4F30-B4C6-B4B80CEFF106"
            if Facter::Util::Resolution.exec(%Q{grep -c /dev/#{p} /proc/mounts}).to_i == 0
              journals << "/dev/#{p}"

            end
          end
        }
      }

        if journals.length > 0
          osds.each { |osd|
            journal = journals.shift
            if (not journal.nil?) && (not journal.empty?)
              devlink = Facter::Util::Resolution.exec(%Q{udevadm info -q property -n #{journal}}).match(/DEVLINKS=(.+)$/)[1].split(' ')
              journal = (devlink.find { |s| s.include? 'by-id' } or journal)
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
