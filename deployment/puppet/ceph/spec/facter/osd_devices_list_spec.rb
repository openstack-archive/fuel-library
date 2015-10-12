require 'spec_helper'

describe "ceph::facter::osd_devices_list", :type => :fact do

  it "should exist" do
    expect(Facter.fact(:osd_devices_list).name).to eq(:osd_devices_list)
  end

  context "with typical block device names" do
    context "OSD without journal"
      before :all do
        Facter.fact(:osfamily).stubs(:value).returns("redhat")
        Facter::Util::Resolution.stubs(:exec).with(%q{lsblk -ln | awk '{if ($6 == "disk") print $1}'}).returns(['sda', 'sdb', 'vda', 'hda'].join("\n"))
        Dir.stubs(:glob).with("/dev/sda?*").returns(["/dev/sda1", "/dev/sda2"])
        Dir.stubs(:glob).with("/dev/sdb?*").returns(["/dev/sdb1"])
        Dir.stubs(:glob).with("/dev/hda?*").returns(["/dev/hda12"])
        Dir.stubs(:glob).with("/dev/vda?*").returns([])
        # Partition GUID code: EBD0A0A2-B9E5-4433-87C0-68B6B72699C7 (Microsoft basic data)
        Facter::Util::Resolution.stubs(:exec).with(%q{sgdisk -i 1 /dev/sda | grep "Partition GUID code" | awk '{print $4}'}).returns("EBD0A0A2-B9E5-4433-87C0-68B6B72699C7\n")
        # Partition GUID code: 0FC63DAF-8483-4772-8E79-3D69D8477DE4 (Linux filesystem)
        Facter::Util::Resolution.stubs(:exec).with(%q{sgdisk -i 2 /dev/sda | grep "Partition GUID code" | awk '{print $4}'}).returns("0FC63DAF-8483-4772-8E79-3D69D8477DE4\n")
        # OSD
        Facter::Util::Resolution.stubs(:exec).with(%q{sgdisk -i 1 /dev/sdb | grep "Partition GUID code" | awk '{print $4}'}).returns("4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D\n")
        Facter::Util::Resolution.stubs(:exec).with(%q{sgdisk -i 12 /dev/hda | grep "Partition GUID code" | awk '{print $4}'}).returns("4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D\n")
        Facter::Util::Resolution.stubs(:exec).with(%q{grep -c /dev/sdb1 /proc/mounts}).returns("0\n")
        Facter::Util::Resolution.stubs(:exec).with(%q{grep -c /dev/hda12 /proc/mounts}).returns("1\n")
      end

      it "should return umounted osd device without journal" do
        expect(Facter.fact(:osd_devices_list).value).to eq("/dev/sdb1")
      end

      after :all do
        Dir.unstub(:glob)
        Facter::Util::Resolution.unstub(:exec)
        Facter.flush
      end
    end

    context "OSD with journal" do
      before :all do
        Facter.fact(:osfamily).stubs(:value).returns("redhat")
        Facter::Util::Resolution.stubs(:exec).with(%q{lsblk -ln | awk '{if ($6 == "disk") print $1}'}).returns("sda")
        Dir.stubs(:glob).with("/dev/sda?*").returns(["/dev/sda1", "/dev/sda2", "/dev/sda3", "/dev/sda4"])
        # OSD with journals
        Facter::Util::Resolution.stubs(:exec).with(%q{sgdisk -i 1 /dev/sda | grep "Partition GUID code" | awk '{print $4}'}).returns("4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D\n")
        Facter::Util::Resolution.stubs(:exec).with(%q{sgdisk -i 2 /dev/sda | grep "Partition GUID code" | awk '{print $4}'}).returns("45B0969E-9B03-4F30-B4C6-B4B80CEFF106\n")
        Facter::Util::Resolution.stubs(:exec).with(%q{sgdisk -i 3 /dev/sda | grep "Partition GUID code" | awk '{print $4}'}).returns("4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D\n")
        Facter::Util::Resolution.stubs(:exec).with(%q{sgdisk -i 4 /dev/sda | grep "Partition GUID code" | awk '{print $4}'}).returns("45B0969E-9B03-4F30-B4C6-B4B80CEFF106\n")
        Facter::Util::Resolution.stubs(:exec).with(%q{udevadm info -q property -n /dev/sda2 | awk 'BEGIN {FS="="} {if ($1 == "DEVLINKS") print $2}'}).returns("/dev/disk/by-id/ata-ST1000DM003-1ER162_Z4Y18F8B-part2 /dev/disk/by-id/wwn-0x5000c5007906728b-part2 /dev/disk/by-uuid/d62a043d-586f-461e-b333-d822d8014301\n")
        Facter::Util::Resolution.stubs(:exec).with(%q{udevadm info -q property -n /dev/sda4 | awk 'BEGIN {FS="="} {if ($1 == "DEVLINKS") print $2}'}).returns("/dev/disk/by-id/ata-ST1000DM003-1ER162_Z4Y18F8B-part4 /dev/disk/by-id/wwn-0x5000c5007906728b-part4 /dev/disk/by-uuid/5E9645E89645C0EF\n")
        Facter::Util::Resolution.stubs(:exec).with(%q{grep -c /dev/sda1 /proc/mounts}).returns("0\n")
        Facter::Util::Resolution.stubs(:exec).with(%q{grep -c /dev/sda2 /proc/mounts}).returns("0\n")
        Facter::Util::Resolution.stubs(:exec).with(%q{grep -c /dev/sda3 /proc/mounts}).returns("0\n")
        Facter::Util::Resolution.stubs(:exec).with(%q{grep -c /dev/sda4 /proc/mounts}).returns("0\n")
      end

      it "should return 2 osd devices with journal" do
        expect(Facter.fact(:osd_devices_list).value).to eq("/dev/sda1:/dev/disk/by-id/ata-ST1000DM003-1ER162_Z4Y18F8B-part2 /dev/sda3:/dev/disk/by-id/ata-ST1000DM003-1ER162_Z4Y18F8B-part4")
      end
       after :all do
        Dir.unstub(:glob)
        Facter::Util::Resolution.unstub(:exec)
        Facter.flush
      end
    end


  context "no OSD devices" do
    before :all do
      Facter::Util::Resolution.stubs(:exec).with(%q{lsblk -ln | awk '{if ($6 == "disk") print $1}'}).returns("sda\n")
      Dir.stubs(:glob).with("/dev/sda?*").returns(["/dev/sda1", "/dev/sda2"])
      Facter::Util::Resolution.stubs(:exec).with(%q{sgdisk -i 1 /dev/sda | grep "Partition GUID code" | awk '{print $4}'}).returns("EBD0A0A2-B9E5-4433-87C0-68B6B72699C7\n")
      Facter::Util::Resolution.stubs(:exec).with(%q{sgdisk -i 2 /dev/sda | grep "Partition GUID code" | awk '{print $4}'}).returns("0FC63DAF-8483-4772-8E79-3D69D8477DE4\n")
    end

    it "should return nil if no devices were detected" do
      expect(Facter.fact(:osd_devices_list).value).to be_empty
    end

    after :all  do
      Dir.unstub(:glob)
      Facter::Util::Resolution.unstub(:exec)
      Facter.flush
    end
  end

  context "with special block device names" do
    before :all do
      Facter.fact(:osfamily).stubs(:value).returns("redhat")
      Facter::Util::Resolution.stubs(:exec).with(%q{lsblk -ln | awk '{if ($6 == "disk") print $1}'}).returns(['cciss!c0d0', 'nvme0n1'].join("\n"))
      Dir.stubs(:glob).with("/dev/cciss/c0d0?*").returns(["/dev/cciss/c0d0p1"])
      Dir.stubs(:glob).with("/dev/nvme0n1?*").returns(["/dev/nvme0n1p1"])
      Facter::Util::Resolution.stubs(:exec).with(%q{sgdisk -i 1 /dev/cciss/c0d0 | grep "Partition GUID code" | awk '{print $4}'}).returns("4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D\n")
      Facter::Util::Resolution.stubs(:exec).with(%q{sgdisk -i 1 /dev/nvme0n1 | grep "Partition GUID code" | awk '{print $4}'}).returns("4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D\n")
      Facter::Util::Resolution.stubs(:exec).with(%q{grep -c /dev/cciss/c0d0p1 /proc/mounts}).returns("0\n")
      Facter::Util::Resolution.stubs(:exec).with(%q{grep -c /dev/nvme0n1p1 /proc/mounts}).returns("0\n")
    end

    it "should return two osd devices without journals" do
      expect(Facter.fact(:osd_devices_list).value).to eq("/dev/cciss/c0d0p1 /dev/nvme0n1p1")
    end
    after :all  do
      Dir.unstub(:glob)
      Facter::Util::Resolution.unstub(:exec)
      Facter.flush
    end

  end
end

# vim: set ts=2 sw=2 et :
