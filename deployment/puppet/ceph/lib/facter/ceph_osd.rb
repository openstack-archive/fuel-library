Facter.add("osd_devices_list") do
    case Facter.value(:osfamily)
    when /(?i)(redhat)/
      sgdisk_exe = "/usr/sbin/sgdisk"
    when /(?i)(debian)/
      sgdisk_exe = "/sbin/sgdisk"
    end

    return unless File.exists?(sgdisk_exe)

    setcode do
        output = []
        disks= []
        osds = []
        journals = []
        devices = Facter::Util::Resolution.exec(%q{lsblk -nr -o KNAME,TYPE}).split("\n").map{|x| x.split}.keep_if{|x| x[1] == "disk"}
        devices.each{|x| disks << x[0]}
        # Finds OSD and journal devices based on Partition GUID
        disks.each { |d|
            # lsblk returns cciss devices as cciss!c0d0p1. The entries
            # in /dev are cciss/c0d0p1
            d.gsub!(/!/, '/')
            device = "/dev/#{d}"
            parts = Dir.glob("#{device}?*").sort
            parts.each { |p|
                pnum = p.gsub(/#{device}p*/, '')
                code = Facter::Util::Resolution.exec(%Q{sgdisk -i #{pnum} #{device}}).match(/Partition GUID code:\s+(\S+)\s/)[1]
                case code
                when "4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D"
                    # Only use unmounted devices
                    if Facter::Util::Resolution.exec(%Q{grep -c #{p} /proc/mounts}).to_i == 0
                        osds << p
                    end
                when "45B0969E-9B03-4F30-B4C6-B4B80CEFF106"
                    if Facter::Util::Resolution.exec(%Q{grep -c #{p} /proc/mounts}).to_i == 0
                        journals << p
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
