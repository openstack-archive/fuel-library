#!/usr/bin/env python

import json
import math
import re

class PManager(object):
    def __init__(self, data):
        if isinstance(data, (str, unicode)):
            self.data = json.loads(data)
        else:
            self.data = data

        self.factor = 1
        self.unit = "MiB"
        self._pre = []
        self._kick = []
        self._post = []
        self.raid_count = 0

        self._pcount = {}
        self._pend = {}
        self._rcount = 0
        self._pvcount = 0

    def _pseparator(self, devname):
        pseparator = ''
        if devname.find('cciss') > 0:
            pseparator = 'p'
        return pseparator

    def pcount(self, disk_id, increment=0):
        self._pcount[disk_id] = self._pcount.get(disk_id, 0) + increment
        return self._pcount.get(disk_id, 0)

    def psize(self, disk_id, increment=0):
        self._pend[disk_id] = self._pend.get(disk_id, 0) + increment
        return self._pend.get(disk_id, 0)

    def rcount(self, increment=0):
        self._rcount += increment
        return self._rcount

    def pvcount(self, increment=0):
        self._pvcount += increment
        return self._pvcount

    def pre(self, command=None):
        if command:
            return self._pre.append(command)
        return self._pre

    def kick(self, command=None):
        if command:
            return self._kick.append(command)
        return self._kick

    def post(self, command=None):
        if command:
            return self._post.append(command)
        return self._post

    def iterdisks(self):
        for item in self.data:
            if item["type"] == "disk" and item["size"] > 0:
                yield item

    def get_partition_count(self, name):
        count = 0
        for disk in self.iterdisks():
            count += len([v for v in disk["volumes"]
                          if v.get('name') == name and v['size'] > 0])
        return count

    def num_ceph_journals(self):
        return self.get_partition_count('cephjournal')

    def num_ceph_osds(self):
        return self.get_partition_count('ceph')

    def _gettabfstype(self, vol):
        if vol.get("file_system"):
            return vol["file_system"]
        elif vol["mount"] == "/":
            return "ext4"
        elif vol["mount"] == "/boot":
            return "ext3"
        elif vol["mount"] == "swap":
            return "swap"
        return "xfs"

    def _getfstype(self, vol):
        fstype = self._gettabfstype(vol)
        if fstype == "swap":
            return ""
        return "--fstype=%s" % fstype

    def _getlabel(self, label):
        if not label:
            return ""
        # XFS will refuse to format a partition if the
        # disk label is > 12 characters.
        return " -L {0} ".format(label[:12])

    def _parttype(self, n):
        return "primary"

    def _getsize(self, vol):
        """Anaconda has hard coded limitation in 16TB
        for ext3/4 and xfs filesystems (the only filesystems
        we are supposed to use). Besides there is no stable
        64-bit ext4 implementation at the moment, so the
        limitation in 16TB for ext4 is not only
        anaconda limitation."""

        """Root partition can not be located on xfs file system
        therefore we check if root filesystem is larger
        than 16TB and set it size into 16TB if it is larger.
        It is necessary to note that to format 16TB
        volume on ext4 it is needed about 1G memory."""
        if vol["size"] > 16777216 and vol["mount"] == "/":
            return 16777216
        return vol["size"]

    def erase_lvm_metadata(self):
        self.pre("for v in $(vgs | awk '{print $1}'); do "
                 "vgreduce -f --removemissing $v; vgremove -f $v; done")
        self.pre("for p in $(pvs | grep '\/dev' | awk '{print $1}'); do "
                 "pvremove -ff -y $p ; done")

    def erase_raid_metadata(self):
        for disk in self.iterdisks():
            self.pre("mdadm --zero-superblock --force /dev/{0}*"
                     "".format(disk['id']))

    def clean(self, disk):
        self.pre("hdparm -z /dev/{0}".format(disk["id"]))
        self.pre("test -e /dev/{0} && dd if=/dev/zero "
                        "of=/dev/{0} bs=1M count=10".format(disk["id"]))
        self.pre("sleep 5")
        self.pre("hdparm -z /dev/{0}".format(disk["id"]))

    def gpt(self, disk):
        self.pre("parted -s /dev/{0} mklabel gpt".format(disk["id"]))

    def bootable(self, disk):
        """Create and mark Bios Boot partition to which grub will
        embed its code later, useable for legacy boot.
        May be way smaller, but be aware that the parted may
        shrink 1M partition to zero at some disks and versions."""
        self.pre("parted -a none -s /dev/{0} "
                 "unit {3} mkpart primary {1} {2}".format(
                     disk["id"],
                     self.psize(disk["id"]),
                     self.psize(disk["id"], 24 * self.factor),
                     self.unit
            )
        )
        self.pre("parted -s /dev/{0} set {1} bios_grub on".format(
                     disk["id"],
                     self.pcount(disk["id"], 1)
            )
        )

        """Create partition for the EFI boot, minimum
        size is 100M, recommended is 200M, with fat32 and
        future mountpoint in the /boot/efi. There is also
        '/usr/sbin/parted -s /dev/sda set 2 boot on'
        which is strictly needed for EFI boot."""
        self.pre("parted -a none -s /dev/{0} "
                 "unit {3} mkpart primary fat32 {1} {2}".format(
                     disk["id"],
                     self.psize(disk["id"]),
                     self.psize(disk["id"], 200 * self.factor),
                     self.unit
            )
        )
        self.pre("parted -s /dev/{0} set {1} boot on".format(
                     disk["id"],
                     self.pcount(disk["id"], 1)
            )
        )

    def boot(self):
        self.plains(volume_filter=lambda x: x["mount"] == "/boot")
        self.raids(volume_filter=lambda x: x["mount"] == "/boot")

    def notboot(self):
        self.plains(volume_filter=lambda x: x["mount"] != "/boot")
        self.raids(volume_filter=lambda x: x["mount"] != "/boot")

    def plains(self, volume_filter=None):
        if not volume_filter:
            volume_filter = lambda x: True

        ceph_osds = self.num_ceph_osds()
        journals_left = ceph_osds
        ceph_journals = self.num_ceph_journals()

        for disk in self.iterdisks():
            for part in filter(lambda p: p["type"] == "partition" and
                               volume_filter(p), disk["volumes"]):
                if part["size"] <= 0:
                    continue

                if part.get('name') == 'cephjournal':
                    # We need to allocate a partition for each ceph OSD
                    # If there is more than one journal device the journals
                    # will be divided evenly amongst them. No more than 10GB
                    # will be allocated to a single journal partition.
                    ratio = math.ceil(float(ceph_osds) / ceph_journals)
                    size = part["size"] / ratio
                    size = size if size <= 10240 else 10240
                    end = ratio if ratio < journals_left else journals_left
                    for i in range(0, end):
                        journals_left -= 1
                        pcount = self.pcount(disk["id"], 1)

                        self.pre("parted -a none -s /dev/{0} "
                                 "unit {4} mkpart {1} {2} {3}".format(
                                     disk["id"],
                                     self._parttype(pcount),
                                     self.psize(disk["id"]),
                                     self.psize(disk["id"], size * self.factor),
                                     self.unit))

                        self.post("chroot /mnt/sysimage sgdisk "
                                  "--typecode={0}:{1} /dev/{2}".format(
                                    pcount, part["partition_guid"],disk["id"]))
                    continue

                pcount = self.pcount(disk["id"], 1)
                self.pre("parted -a none -s /dev/{0} "
                         "unit {4} mkpart {1} {2} {3}".format(
                             disk["id"],
                             self._parttype(pcount),
                             self.psize(disk["id"]),
                             self.psize(disk["id"], part["size"] * self.factor),
                             self.unit))

                fstype = self._getfstype(part)
                size = self._getsize(part)
                tabmount = part["mount"] if part["mount"] != "swap" else "none"
                tabfstype = self._gettabfstype(part)
                if part.get("partition_guid"):
                    self.post("chroot /mnt/sysimage sgdisk "
                              "--typecode={0}:{1} /dev/{2}".format(
                                pcount, part["partition_guid"],disk["id"]))
                if size > 0 and size <= 16777216 and part["mount"] != "none":
                    self.kick("partition {0} "
                              "--onpart=$(readlink -f /dev/{2})"
                              "{3}{4}".format(part["mount"], size,
                                           disk["id"],
                                           self._pseparator(disk["id"]),
                                           pcount))
                else:
                    if part["mount"] != "swap" and tabfstype != "none":
                        disk_label = self._getlabel(part.get('disk_label'))
                        self.post("mkfs.{0} -f $(readlink -f /dev/{1})"
                                  "{2}{3} {4}".format(tabfstype, disk["id"],
                                                   self._pseparator(disk["id"]),
                                                   pcount, disk_label))
                        if part["mount"] != "none":
                            self.post("mkdir -p /mnt/sysimage{0}".format(
                                part["mount"]))

                    if tabfstype != "none":
                        self.post("echo 'UUID=$(blkid -s UUID -o value "
                                  "$(readlink -f /dev/{0}){1}{2}) "
                                  "{3} {4} defaults 0 0'"
                                  " >> /mnt/sysimage/etc/fstab".format(
                                      disk["id"], self._pseparator(disk["id"]),
                                      pcount, tabmount, tabfstype))

    def raids(self, volume_filter=None):
        if not volume_filter:
            volume_filter = lambda x: True
        raids = {}
        raid_info = {}
        phys = {}
        for disk in self.iterdisks():
            for raid in filter(lambda p: p["type"] == "raid" and
                               volume_filter(p), disk["volumes"]):
                if raid["size"] <= 0:
                    continue
                raid_info[raid["mount"]] = raid
                pcount = self.pcount(disk["id"], 1)
                if not phys.get(raid["mount"]):
                    phys[raid["mount"]] = []
                phys[raid["mount"]].append("$(readlink -f /dev/{0}){1}{2}".
                    format(disk["id"], self._pseparator(disk["id"]), pcount))
                rname = "raid.{0:03d}".format(self.rcount(1))
                begin_size = self.psize(disk["id"])
                end_size = self.psize(disk["id"], raid["size"] * self.factor)
                self.pre("parted -a none -s /dev/{0} "
                         "unit {4} mkpart {1} {2} {3}".format(
                             disk["id"], self._parttype(pcount),
                             begin_size, end_size, self.unit))
                self.kick("partition {0} "
                          "--onpart=$(readlink -f /dev/{2}){3}{4}"
                          "".format(rname, raid["size"], disk["id"],
                                    self._pseparator(disk["id"]), pcount))

                if not raids.get(raid["mount"]):
                    raids[raid["mount"]] = []
                raids[raid["mount"]].append(rname)

        for (num, (mount, rnames)) in enumerate(raids.iteritems()):
            raid = raid_info[mount]
            fstype = self._gettabfstype(raid)
            label = raid.get('disk_label')
            # Anaconda won't label a RAID array. It also can't create
            # a single-drive RAID1 array, but mdadm can.
            if label or len(rnames) == 1:
                if len(rnames) == 1:
                    phys[mount].append('missing')
                self.post("mdadm --create /dev/md{0} --run --level=1 "
                            "--raid-devices={1} {2}".format(self.raid_count,
                            len(phys[mount]), ' '.join(phys[mount])))
                self.post("mkfs.{0} -f {1} /dev/md{2}".format(
                          fstype, self._getlabel(label), self.raid_count))
                self.post("mdadm --detail --scan | grep '\/dev\/md{0}'"
                          ">> /mnt/sysimage/etc/mdadm.conf".format(
                          self.raid_count))
                self.post("mkdir -p /mnt/sysimage{0}".format(mount))
                self.post("echo \\\"UUID=\$(blkid -s UUID -o value "
                          "/dev/md{0}) "
                          "{1} {2} defaults 0 0\\\""
                          " >> /mnt/sysimage/etc/fstab".format(
                             self.raid_count, mount, fstype))
            else:
                self.kick("raid {0} --device md{1} --fstype {3} "
                    "--level=RAID1 {2}".format(mount, self.raid_count,
                    " ".join(rnames), fstype))
            self.raid_count += 1

    def pvs(self):
        pvs = {}
        for disk in self.iterdisks():
            for pv in [p for p in disk["volumes"] if p["type"] == "pv"]:
                if pv["size"] <= 0:
                    continue
                pcount = self.pcount(disk["id"], 1)
                pvname = "pv.{0:03d}".format(self.pvcount(1))
                begin_size = self.psize(disk["id"])
                end_size = self.psize(disk["id"], pv["size"] * self.factor)
                self.pre("parted -a none -s /dev/{0} "
                         "unit {4} mkpart {1} {2} {3}".format(
                             disk["id"], self._parttype(pcount),
                             begin_size, end_size, self.unit))
                self.kick("partition {0} "
                          "--onpart=$(readlink -f /dev/{2}){3}{4}"
                          "".format(pvname, pv["size"], disk["id"],
                                    self._pseparator(disk["id"]), pcount))

                if not pvs.get(pv["vg"]):
                    pvs[pv["vg"]] = []
                pvs[pv["vg"]].append(pvname)

        for vg, pvnames in pvs.iteritems():
            self.kick("volgroup {0} {1}".format(vg, " ".join(pvnames)))


    def lvs(self):
        for vg in [g for g in self.data if g["type"] == "vg"]:
            for lv in vg["volumes"]:
                if lv["size"] <= 0:
                    continue
                fstype = self._getfstype(lv)
                size = self._getsize(lv)
                tabmount = lv["mount"] if lv["mount"] != "swap" else "none"
                tabfstype = self._gettabfstype(lv)

                if size > 0 and size <= 16777216:
                    self.kick("logvol {0} --vgname={1} --size={2} "
                              "--name={3} {4}".format(
                                  lv["mount"], vg["id"], size,
                                  lv["name"], fstype))
                else:
                    self.post("lvcreate --size {0} --name {1} {2}".format(
                        size, lv["name"], vg["id"]))
                    if lv["mount"] != "swap" and tabfstype != "none":
                        self.post("mkfs.{0} /dev/mapper/{1}-{2}".format(
                            tabfstype, vg["id"], lv["name"]))
                        self.post("mkdir -p /mnt/sysimage{0}"
                                  "".format(lv["mount"]))

                    if tabfstype != "none":
                        """
                        The name of the device. An LVM device is
                        expressed as the volume group name and the logical
                        volume name separated by a hyphen. A hyphen in
                        the original name is translated to two hyphens.
                        """
                        self.post("echo '/dev/mapper/{0}-{1} {2} {3} "
                                  "defaults 0 0'"
                                  " >> /mnt/sysimage/etc/fstab".format(
                                      vg["id"].replace("-", "--"),
                                      lv["name"].replace("-", "--"),
                                      tabmount, tabfstype))

    def bootloader(self):
        devs = []
        for disk in self.iterdisks():
            devs.append("$(basename `readlink -f /dev/{0}`)"
                        "".format(disk["id"]))
        if devs:
            self.kick("bootloader --location=mbr --driveorder={0} "
                      "--append=' biosdevname=0 "
                      "crashkernel=none'".format(",".join(devs)))
            for dev in devs:
                self.post("echo -n > /tmp/grub.script")
                self.post("echo \\\"device (hd0) /dev/{0}\\\" >> "
                          "/tmp/grub.script".format(dev))
                """
                This means that we set drive geometry manually into to
                avoid grub register overlapping. We set it so that grub
                thinks disk size is equal to 1G.
                130 cylinders * (16065 * 512 = 8225280 bytes) = 1G
                """
                self.post("echo \\\"geometry (hd0) 130 255 63\\\" >> "
                          "/tmp/grub.script")
                self.post("echo \\\"root (hd0,2)\\\" >> /tmp/grub.script")
                self.post("echo \\\"install /grub/stage1 (hd0) /grub/stage2 p "
                          "/grub/grub.conf\\\" >> /tmp/grub.script")
                self.post("echo quit >> /tmp/grub.script")
                self.post("cat /tmp/grub.script | chroot /mnt/sysimage "
                          "/sbin/grub --no-floppy --batch")

    def expose(self,
               kickfile="/tmp/partition.ks",
               postfile="/tmp/post_partition.ks"
        ):
        result = ""
        for pre in self.pre():
            result += "{0}\n".format(pre)

        result += "echo > {0}\n".format(kickfile)
        for kick in self.kick():
            result += "echo \"{0}\" >> {1}\n".format(kick, kickfile)

        result += "echo \"%post --nochroot\" > {0}\n".format(postfile)
        result += "echo \"set -x -v\" >> {0}\n".format(postfile)
        result += ("echo \"exec 1>/mnt/sysimage/root/post-partition.log "
                   "2>&1\" >> {0}\n".format(postfile))
        for post in self.post():
            result += "echo \"{0}\" >> {1}\n".format(post, postfile)
        result += "echo \"%end\" >> {0}\n".format(postfile)
        return result

    def eval(self):
        for disk in self.iterdisks():
            self.clean(disk)
            self.gpt(disk)
            self.bootable(disk)
        self.boot()
        self.notboot()
        self.pvs()
        self.lvs()
        self.bootloader()
        self.pre("sleep 10")
        for disk in self.iterdisks():
            self.pre("hdparm -z /dev/{0}".format(disk["id"]))
        self.erase_lvm_metadata()
        self.erase_raid_metadata()


class PreseedPManager(object):
    def __init__(self, data):
        if isinstance(data, (str, unicode)):
            self.data = json.loads(data)
        else:
            self.data = data

        self.factor = 1
        self.unit = "MiB"
        self.disks = sorted(["/dev/" + d["id"] for d in self.iterdisks()])

        self._pcount = {}
        self._pend = {}
        self._recipe = []
        self._late = []
        self._early = []

    def iterdisks(self):
        for item in self.data:
            if item["type"] == "disk" and item["size"] > 0:
                yield item

    def recipe(self, command=None):
        if command:
            return self._recipe.append(command)
        return self._recipe

    def late(self, command=None, in_target=False):
        if command:
            return self._late.append((command, in_target))
        return self._late

    def early(self, command=None):
        if command:
            return self._early.append(command)
        return self._early

    def _pseparator(self, devname):
        pseparator = ''
        if devname.find('cciss') > 0:
            pseparator = 'p'
        return pseparator

    def _getlabel(self, label):
        if not label:
            return ""
        # XFS will refuse to format a partition if the
        # disk label is > 12 characters.
        return " -L {0} ".format(label[:12])

    def _parttype(self, n):
        return "primary"

    def pcount(self, disk_id, increment=0):
        self._pcount[disk_id] = self._pcount.get(disk_id, 0) + increment
        return self._pcount.get(disk_id, 0)

    def psize(self, disk_id, increment=0):
        self._pend[disk_id] = self._pend.get(disk_id, 0) + increment
        return self._pend.get(disk_id, 0)

    def get_partition_count(self, name):
        count = 0
        for disk in self.iterdisks():
            count += len([v for v in disk["volumes"]
                          if v.get('name') == name and v['size'] > 0])
        return count

    def num_ceph_journals(self):
        return self.get_partition_count('cephjournal')

    def num_ceph_osds(self):
        return self.get_partition_count('ceph')

    def erase_partition_table(self):
        for disk in self.iterdisks():
            self.early("test -e $(readlink -f /dev/{0}) && "
                       "dd if=/dev/zero of=$(readlink -f /dev/{0}) "
                       "bs=1M count=10".format(disk["id"]))
            self.early("sleep 3")
            self.early("hdparm -z $(readlink -f /dev/{0})".format(disk["id"]))

    def log_lvm(self, line, early=True):
        func = self.early
        if not early:
            func = self.late
        func("echo \"=== {0} ===\" | logger".format(line))
        func("for v in $(vgs -a --noheadings 2>/dev/null | "
                  "sed 's/^\([ ]*\)\([^ ]\+\)\(.*\)/\\2/g'); do "
                  "echo \"vg=$v\" | logger; done")
        func("for p in $(pvs --noheadings 2>/dev/null | "
                  "sed 's/^\([ ]*\)\([^ ]\+\)\(.*\)/\\2/g'); do "
                  "echo \"pv=$p\" | logger; done")

    def erase_lvm_metadata(self, early=True):
        func = self.early
        if not early:
            func = self.late

        func("for v in $(vgs -a --noheadings 2>/dev/null | "
             "sed 's/^\([ ]*\)\([^ ]\+\)\(.*\)/\\2/g'); do "
             "vgreduce --force --removemissing $v; "
             "vgremove --force $v; done")
        func("for p in $(pvs --noheadings 2>/dev/null | "
             "sed 's/^\([ ]*\)\([^ ]\+\)\(.*\)/\\2/g'); do "
             "pvremove -ff -y $p; done")

    def boot(self):
        self.recipe("24 24 24 ext3 "
                    "$gptonly{ } "
                    "$bios_boot{ } "
                    "method{ biosgrub } .")
        self.psize(self.disks[0], 24 * self.factor)
        self.pcount(self.disks[0], 1)

        self.late("parted -s $(readlink -f {0}) set {1} bios_grub on".format(
                    self.disks[0],
                    self.pcount(self.disks[0])
            )
        )

        self.recipe("200 200 200 ext3 $primary{ } "
                    "$gptonly{ } "
                    "$bootable{ } method{ format } format{ } use_filesystem{ } "
                    "filesystem{ ext3 } mountpoint{ /boot } .")
        self.pcount(self.disks[0], 1)
        self.psize(self.disks[0], 200 * self.factor)

    def os(self):
        for vg in [v for v in self.data
                   if v["type"] == "vg" and v["id"] == "os"]:
            for vol in vg["volumes"]:
                if vol["mount"] == "swap":
                    swap_size = vol["size"]
                elif vol["mount"] == "/":
                    root_size = vol["size"]

        self.recipe("{0} {0} {0} ext4 "
                    "$gptonly{{ }} "
                    "method{{ format }} format{{ }} use_filesystem{{ }} "
                    "filesystem{{ ext4 }} mountpoint{{ / }} ."
                    "".format(root_size))
        self.pcount(self.disks[0], 1)
        self.psize(self.disks[0], root_size * self.factor)
        self.recipe("{0} {0} {0} linux-swap "
                    "$gptonly{{ }} "
                    "method{{ swap }} format{{ }} .".format(swap_size))
        self.pcount(self.disks[0], 1)
        self.psize(self.disks[0], swap_size * self.factor)
        """
        We need this line because debian-installer takes total disk space
        for the last partition. So to be able to allocate custom partitions
        during the late stage we need to create fake swap partition that
        we then destroy.
        """
        self.recipe("1 1 -1 ext3 $gptonly{ } method{ keep } .")
        self.late("parted $(readlink -f {0}) rm 5".format(self.disks[0]))
        self.late("sleep 3")
        self.late("hdparm -z $(readlink -f {0})".format(self.disks[0]))

    def partitions(self):
        ceph_osds = self.num_ceph_osds()
        journals_left = ceph_osds
        ceph_journals = self.num_ceph_journals()

        for disk in self.iterdisks():
            for part in filter(lambda p: p["type"] == "partition" and
                               p["mount"] != "/boot", disk["volumes"]):
                if part["size"] <= 0:
                    continue

                if self.pcount("/dev/%s" % disk["id"]) == 0:
                    self.late("parted -s $(readlink -f /dev/{0}) mklabel gpt"
                              "".format(disk["id"]))
                    self.late("parted -a none -s $(readlink -f /dev/{0}) "
                        "unit {3} mkpart primary {1} {2}".format(
                            disk["id"],
                            self.psize("/dev/%s" % disk["id"]),
                            self.psize("/dev/%s" % disk["id"],
                                       24 * self.factor),
                            self.unit
                        )
                    )
                    self.late("parted -s $(readlink -f /dev/{0}) set {1} "
                              "bios_grub on".format(
                                  disk["id"],
                                  self.pcount("/dev/%s" % disk["id"], 1)
                        )
                    )

                if part.get('name') == 'cephjournal':
                    # We need to allocate a partition for each ceph OSD
                    # If there is more than one journal device the journals
                    # will be divided evenly amongst them. No more than 10GB
                    # will be allocated to a single journal partition.
                    ratio = math.ceil(float(ceph_osds) / ceph_journals)
                    size = part["size"] / ratio
                    size = size if size <= 10240 else 10240
                    end = ratio if ratio < journals_left else journals_left
                    for i in range(0, end):
                        journals_left -= 1
                        pcount = self.pcount('/dev/%s' % disk["id"], 1)

                        self.late("parted -a none -s /dev/{0} "
                                 "unit {4} mkpart {1} {2} {3}".format(
                                     disk["id"],
                                     self._parttype(pcount),
                                     self.psize('/dev/%s' % disk["id"]),
                                     self.psize('/dev/%s' % disk["id"], size * self.factor),
                                     self.unit))

                        self.late("sgdisk --typecode={0}:{1} /dev/{2}"
                                  "".format(pcount, part["partition_guid"],
                                            disk["id"]), True)
                    continue

                pcount = self.pcount("/dev/%s" % disk["id"], 1)
                tabmount = part["mount"] if part["mount"] != "swap" else "none"
                self.late("parted -a none -s $(readlink -f /dev/{0}) "
                          "unit {4} mkpart {1} {2} {3}".format(
                             disk["id"],
                             self._parttype(pcount),
                             self.psize("/dev/%s" % disk["id"]),
                             self.psize("/dev/%s" % disk["id"],
                                        part["size"] * self.factor),
                             self.unit))
                self.late("sleep 3")
                self.late("hdparm -z $(readlink -f /dev/{0})"
                          "".format(disk["id"]))

                if part.get("partition_guid"):
                    self.late("sgdisk --typecode={0}:{1} /dev/{2}"
                              "".format(pcount, part["partition_guid"],
                                        disk["id"]), True)

                if not part.get("file_system", "xfs") in ("swap", None, "none"):
                    disk_label = self._getlabel(part.get("disk_label"))
                    self.late("mkfs.{0} -f $(readlink -f /dev/{1}){2}{3} {4}"
                              "".format(part.get("file_system", "xfs"),
                                        disk["id"],
                                        self._pseparator(disk["id"]),
                                        pcount, disk_label))
                if not part["mount"] in (None, "none", "swap"):
                    self.late("mkdir -p /target{0}".format(part["mount"]))
                if not part["mount"] in (None, "none"):
                    self.late("echo 'UUID=$(blkid -s UUID -o value "
                              "$(readlink -f /dev/{0}){1}{2}) "
                              "{3} {4} {5} 0 0'"
                              " >> /target/etc/fstab"
                              "".format(
                                  disk["id"], self._pseparator(disk["id"]),
                                  pcount, tabmount,
                                  part.get("file_system", "xfs"),
                                  ("defaults" if part["mount"] != "swap"
                                   else "sw" )))

    def lv(self):
        self.log_lvm("before creating lvm", False)

        devices_dict = {}
        pvlist = []

        for disk in self.iterdisks():
            for pv in [p for p in disk["volumes"]
                       if p["type"] == "pv" and p["vg"] != "os"]:
                if pv["size"] <= 0:
                    continue
                if self.pcount("/dev/%s" % disk["id"]) == 0:
                    self.late("parted -s $(readlink -f /dev/{0}) mklabel gpt"
                              "".format(disk["id"]))
                    self.late("parted -a none -s $(readlink -f /dev/{0}) "
                        "unit {3} mkpart primary {1} {2}".format(
                            disk["id"],
                            self.psize("/dev/%s" % disk["id"]),
                            self.psize("/dev/%s" % disk["id"],
                                       24 * self.factor),
                            self.unit
                        )
                    )
                    self.late("parted -s $(readlink -f /dev/{0}) set {1} "
                              "bios_grub on".format(
                                  disk["id"],
                                  self.pcount("/dev/%s" % disk["id"], 1)))

                pcount = self.pcount("/dev/%s" % disk["id"], 1)
                begin_size = self.psize("/dev/%s" % disk["id"])
                end_size = self.psize("/dev/%s" % disk["id"],
                                      pv["size"] * self.factor)

                self.late("parted -a none -s $(readlink -f /dev/{0}) "
                          "unit {4} mkpart {1} {2} {3}".format(
                             disk["id"],
                             self._parttype(pcount),
                             begin_size,
                             end_size,
                             self.unit))

                self.late("sleep 3")
                self.late("hdparm -z $(readlink -f /dev/{0})"
                          "".format(disk["id"]))
                pvlist.append("pvcreate -ff $(readlink -f /dev/{0}){1}{2}"
                              "".format(disk["id"],
                                        self._pseparator(disk["id"]),
                                        pcount))
                if not devices_dict.get(pv["vg"]):
                    devices_dict[pv["vg"]] = []
                devices_dict[pv["vg"]].append(
                    "$(readlink -f /dev/{0}){1}{2}"
                    "".format(disk["id"], self._pseparator(disk["id"]), pcount)
                )

        self.log_lvm("before additional cleaning", False)
        self.erase_lvm_metadata(False)

        self.log_lvm("before pvcreate", False)
        for pvcommand in pvlist:
            self.late(pvcommand)

        self.log_lvm("before vgcreate", False)
        for vg, devs in devices_dict.iteritems():
            self.late("vgcreate -s 32m {0} {1}".format(vg, " ".join(devs)))

        self.log_lvm("after vgcreate", False)

        for vg in [v for v in self.data
                   if v["type"] == "vg" and v["id"] != "os"]:
            for lv in vg["volumes"]:
                if lv["size"] <= 0:
                    continue
                self.late("lvcreate -L {0}m -n {1} {2}".format(
                    lv["size"], lv["name"], vg["id"]))
                self.late("sleep 5")
                self.late("lvscan")

                tabmount = lv["mount"] if lv["mount"] != "swap" else "none"
                if ((not lv.get("file_system", "xfs") in ("swap", None, "none"))
                    and (not lv["mount"] in ("swap", "/"))):
                    self.late("mkfs.{0} /dev/mapper/{1}-{2}".format(
                        lv.get("file_system", "xfs"),
                        vg["id"].replace("-", "--"),
                        lv["name"].replace("-", "--")))
                if not lv["mount"] in (None, "none", "swap", "/"):
                    self.late("mkdir -p /target{0}".format(lv["mount"]))
                if not lv["mount"] in (None, "none", "swap", "/"):
                    self.late("echo '/dev/mapper/{0}-{1} "
                              "{2} {3} {4} 0 0' >> /target/etc/fstab"
                              "".format(
                                  vg["id"].replace("-", "--"),
                                  lv["name"].replace("-", "--"),
                                  tabmount,
                                  lv.get("file_system", "xfs"),
                                  ("defaults" if lv["mount"] != "swap"
                                   else "sw" )))

    def eval(self):
        self.log_lvm("before early lvm cleaning")
        self.erase_lvm_metadata()
        self.log_lvm("after early lvm cleaning")
        self.erase_partition_table()
        self.boot()
        self.os()
        self.lv()
        self.partitions()
        self.late("apt-get install -y grub-pc", True)
        self.late("umount /target/proc")
        self.late("mount -o bind /proc /target/proc")
        self.late("umount /target/sys")
        self.late("mount -o bind /sys /target/sys")
        self.late("grub-mkconfig", True)
        self.late("grub-mkdevicemap", True)
        for disk in self.iterdisks():
            self.late("grub-install $(readlink -f /dev/{0})"
                      "".format(disk["id"]), True)
        self.late("update-grub", True)

    def expose_recipe(self):
        return " \\\n".join(self.recipe())

    def expose_late(self, gzip=False):
        result = ""
        for line, in_target in self.late():
            result += "{0}{1};\\\n".format(
                ("in-target " if in_target else ""), line)
        return result.rstrip()

    def expose_early(self):
        result = ""
        for line in self.early():
            result += "{0};\\\n".format(line)
        return result.rstrip()

    def expose_disks(self):
        return "$(readlink -f {0})".format(self.disks[0])


def pm(data):
    pmanager = PManager(data)
    pmanager.eval()
    return pmanager.expose()

example = """
[
    {
        "name": "sda",
        "free_space": 101772,
        "volumes": [
            {
                "type": "boot",
                "size": 300
            },
            {
                "mount": "/boot",
                "type": "raid",
                "size": 200
            },
            {
                "type": "lvm_meta_pool",
                "size": 0
            },
            {
                "size": 12352,
                "type": "pv",
                "lvm_meta_size": 64,
                "vg": "os"
            },
            {
                "size": 89548,
                "type": "pv",
                "lvm_meta_size": 64,
                "vg": "image"
            }
        ],
        "type": "disk",
        "id": "disk/by-path/pci-0000:00:06.0-scsi-0:0:0:0",
        "size": 102400
    },
    {
        "name": "sdb",
        "free_space": 101772,
        "volumes": [
            {
                "type": "boot",
                "size": 300
            },
            {
                "mount": "/boot",
                "type": "raid",
                "size": 200
            },
            {
                "type": "lvm_meta_pool",
                "size": 64
            },
            {
                "size": 0,
                "type": "pv",
                "lvm_meta_size": 0,
                "vg": "os"
            },
            {
                "size": 101836,
                "type": "pv",
                "lvm_meta_size": 64,
                "vg": "image"
            }
        ],
        "type": "disk",
        "id": "disk/by-path/pci-0000:00:06.0-scsi-0:0:1:0",
        "size": 102400
    },
    {
        "min_size": 12288,
        "type": "vg",
        "id": "os",
        "volumes": [
            {
                "mount": "/",
                "type": "lv",
                "name": "root",
                "size": 10240
            },
            {
                "mount": "swap",
                "type": "lv",
                "name": "swap",
                "size": 2048
            }
        ],
        "label": "Base System"
    },
    {
        "min_size": 5120,
        "type": "vg",
        "id": "image",
        "volumes": [
            {
                "mount": "/var/lib/glance",
                "type": "lv",
                "name": "glance",
                "size": 191256
            }
        ],
        "label": "Image Storage"
    }
]
"""

# pmanager = PreseedPManager(example)
# pmanager.eval()
# print pmanager.expose_late()
