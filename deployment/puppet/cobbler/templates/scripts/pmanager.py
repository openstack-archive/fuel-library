#!/usr/bin/env python

import json

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

        self._pcount = {}
        self._pend = {}
        self._rcount = 0
        self._pvcount = 0

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

    def _gettabfstype(self, vol):
        if vol["mount"] == "/":
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
        self.pre("for v in $(vgs | awk '{print $1}'); do" 
                    "vgreduce -ff --removemissing $v; vgremove -ff $v; done")
        self.pre("for p in $(pvs | grep '\/dev' | awk '{print $1}'); do"
                    "pvremove -ff -y $p ; done")

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
        for disk in [d for d in self.data if d["type"] == "disk"]:
            for part in filter(lambda p: p["type"] == "partition" and
                               volume_filter(p), disk["volumes"]):
                if part["size"] <= 0:
                    continue
                pcount = self.pcount(disk["id"],   1)
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
                if size > 0 and size <= 16777216 and part["mount"] != "none":
                    self.kick("partition {0} "
                              "--onpart=$(readlink -f /dev/{2})"
                              "{3}".format(part["mount"], size,
                                           disk["id"], pcount))
                else:
                    if part["mount"] != "swap":
                        disk_label = ""
                        if part.get("disk_label"):
                            # XFS will refuse to format a partition if the
                            # disk label is > 12 characters.
                            disk_label = "-L {0}".format(
                                part["disk_label"][:12])
                        self.post("mkfs.{0} $(readlink -f /dev/{1})"
                                  "{2} {3}".format(tabfstype, disk["id"],
                                                   pcount, disk_label))
                        if part["mount"] != "none":
                            self.post("mkdir -p /mnt/sysimage{0}".format(
                                part["mount"]))

                    self.post("echo 'UUID=$(blkid -s UUID -o value "
                              "$(readlink -f /dev/{0}){1}) "
                              "{2} {3} defaults 0 0'"
                              " >> /mnt/sysimage/etc/fstab".format(
                                  disk["id"], pcount, tabmount, tabfstype))

    def raids(self, volume_filter=None):
        if not volume_filter:
            volume_filter = lambda x: True
        raids = {}
        for disk in [d for d in self.data if d["type"] == "disk"]:
            for raid in filter(lambda p: p["type"] == "raid" and
                               volume_filter(p), disk["volumes"]):
                if raid["size"] <= 0:
                    continue
                pcount = self.pcount(disk["id"], 1)
                rname = "raid.{0:03d}".format(self.rcount(1))
                begin_size = self.psize(disk["id"])
                end_size = self.psize(disk["id"], raid["size"] * self.factor)
                self.pre("parted -a none -s /dev/{0} "
                         "unit {4} mkpart {1} {2} {3}".format(
                             disk["id"], self._parttype(pcount),
                             begin_size, end_size, self.unit))
                self.kick("partition {0} "
                          "--onpart=$(readlink -f /dev/{2}){3}"
                          "".format(rname, raid["size"], disk["id"], pcount))

                if not raids.get(raid["mount"]):
                    raids[raid["mount"]] = []
                raids[raid["mount"]].append(rname)

        for (num, (mount, rnames)) in enumerate(raids.iteritems()):
            fstype = self._gettabfstype({"mount": mount})
            self.kick("raid {0} --device md{1} --fstype ext2 "
                      "--level=RAID1 {2}".format(mount, num, " ".join(rnames)))

    def pvs(self):
        pvs = {}
        for disk in [d for d in self.data if d["type"] == "disk"]:
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
                          "--onpart=$(readlink -f /dev/{2}){3}"
                          "".format(pvname, pv["size"], disk["id"], pcount))

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
                    if lv["mount"] != swap:
                        self.post("mkfs.{0} /dev/mapper/{1}-{2}".format(
                            tabfstype, vg["id"], lv["name"]))
                        self.post("mkdir -p /mnt/sysimage{0}"
                                  "".format(lv["mount"]))
                    """
                    The name of the device. An LVM device is
                    expressed as the volume group name and the logical
                    volume name separated by a hyphen. A hyphen in
                    the original name is translated to two hyphens.
                    """
                    self.post("echo '/dev/mapper/{0}-{1} {2} {3} defaults 0 0'"
                              " >> /mnt/sysimage/etc/fstab".format(
                                  vg["id"].replace("-", "--"),
                                  lv["name"].replace("-", "--"),
                                  tabmount, tabfstype))

    def bootloader(self):
        devs = []
        for disk in [d for d in self.data if d["type"] == "disk"]:
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
        for disk in [d for d in self.data if d["type"] == "disk"]:
            self.clean(disk)
            self.gpt(disk)
            self.bootable(disk)
        self.boot()
        self.notboot()
        self.pvs()
        self.lvs()
        self.bootloader()
        self.pre("sleep 10")
        for disk in [d for d in self.data if d["type"] == "disk"]:
            self.pre("hdparm -z /dev/{0}".format(disk["id"]))
        self.erase_lvm_metadata()


def pm(data):
    pmanager = PManager(data)
    pmanager.eval()
    return pmanager.expose()

