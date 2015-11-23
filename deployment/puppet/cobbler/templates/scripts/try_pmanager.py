#!/uar/bin/env python

import sys
import os
import json
import re

sys.path[:1] = ["."]

import pmanager

data = """
{
    "kernel_params": "abc=cde",
    "ks_spaces": [
        {
            "name": "sda",
            "extra": [
                "disk/by-id/wwn-0x5001e820027832ac",
                "disk/by-id/scsi-35001e820027832ac"
            ],
            "free_space": 76266,
            "volumes": [
                {
                    "type": "boot",
                    "size": 300
                },
                {
                    "mount": "/boot",
                    "size": 200,
                    "type": "raid",
                    "file_system": "ext2",
                    "name": "Boot"
                },
                {
                    "type": "lvm_meta_pool",
                    "size": 0
                },
                {
                    "partition_guid": "45b0969e-9b03-4f30-b4c6-b4b80ceff106",
                    "name": "cephjournal",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 71700
                },
                {
                    "partition_guid": "4fbd7e29-9d25-41b8-afd0-062c0ceff05d",
                    "name": "ceph",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 0
                },
                {
                    "vg": "os",
                    "type": "pv",
                    "lvm_meta_size": 64,
                    "size": 42316
                }
            ],
            "type": "disk",
            "id": "disk/by-path/pci-0000:03:00.0-scsi-0:0:0:0",
            "size": 190782
        },
        {
            "name": "sdb",
            "extra": [
                "disk/by-id/wwn-0x5000c5007253b7d3",
                "disk/by-id/scsi-35000c5007253b7d3"
            ],
            "free_space": 0,
            "volumes": [
                {
                    "type": "boot",
                    "size": 300
                },
                {
                    "mount": "/boot",
                    "size": 200,
                    "type": "raid",
                    "file_system": "ext2",
                    "name": "Boot"
                },
                {
                    "type": "lvm_meta_pool",
                    "size": 64
                },
                {
                    "partition_guid": "45b0969e-9b03-4f30-b4c6-b4b80ceff106",
                    "name": "cephjournal",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 0
                },
                {
                    "partition_guid": "4fbd7e29-9d25-41b8-afd0-062c0ceff05d",
                    "name": "ceph",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 1144077
                },
                {
                    "vg": "os",
                    "type": "pv",
                    "lvm_meta_size": 0,
                    "size": 0
                }
            ],
            "type": "disk",
            "id": "disk/by-path/pci-0000:03:00.0-scsi-0:0:1:0",
            "size": 1144641
        },
        {
            "name": "sdc",
            "extra": [
                "disk/by-id/wwn-0x5000c5007247655f",
                "disk/by-id/scsi-35000c5007247655f"
            ],
            "free_space": 0,
            "volumes": [
                {
                    "type": "boot",
                    "size": 300
                },
                {
                    "mount": "/boot",
                    "size": 200,
                    "type": "raid",
                    "file_system": "ext2",
                    "name": "Boot"
                },
                {
                    "type": "lvm_meta_pool",
                    "size": 64
                },
                {
                    "partition_guid": "45b0969e-9b03-4f30-b4c6-b4b80ceff106",
                    "name": "cephjournal",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 0
                },
                {
                    "partition_guid": "4fbd7e29-9d25-41b8-afd0-062c0ceff05d",
                    "name": "ceph",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 1144077
                },
                {
                    "vg": "os",
                    "type": "pv",
                    "lvm_meta_size": 0,
                    "size": 0
                }
            ],
            "type": "disk",
            "id": "disk/by-path/pci-0000:03:00.0-scsi-0:0:2:0",
            "size": 1144641
        },
        {
            "name": "sdd",
            "extra": [
                "disk/by-id/wwn-0x5000c500724a6c2b",
                "disk/by-id/scsi-35000c500724a6c2b"
            ],
            "free_space": 0,
            "volumes": [
                {
                    "type": "boot",
                    "size": 300
                },
                {
                    "mount": "/boot",
                    "size": 200,
                    "type": "raid",
                    "file_system": "ext2",
                    "name": "Boot"
                },
                {
                    "type": "lvm_meta_pool",
                    "size": 64
                },
                {
                    "partition_guid": "45b0969e-9b03-4f30-b4c6-b4b80ceff106",
                    "name": "cephjournal",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 0
                },
                {
                    "partition_guid": "4fbd7e29-9d25-41b8-afd0-062c0ceff05d",
                    "name": "ceph",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 1144077
                },
                {
                    "vg": "os",
                    "type": "pv",
                    "lvm_meta_size": 0,
                    "size": 0
                }
            ],
            "type": "disk",
            "id": "disk/by-path/pci-0000:03:00.0-scsi-0:0:3:0",
            "size": 1144641
        },
        {
            "name": "sde",
            "extra": [
                "disk/by-id/wwn-0x5000c500724a0707",
                "disk/by-id/scsi-35000c500724a0707"
            ],
            "free_space": 0,
            "volumes": [
                {
                    "type": "boot",
                    "size": 300
                },
                {
                    "mount": "/boot",
                    "size": 200,
                    "type": "raid",
                    "file_system": "ext2",
                    "name": "Boot"
                },
                {
                    "type": "lvm_meta_pool",
                    "size": 64
                },
                {
                    "partition_guid": "45b0969e-9b03-4f30-b4c6-b4b80ceff106",
                    "name": "cephjournal",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 0
                },
                {
                    "partition_guid": "4fbd7e29-9d25-41b8-afd0-062c0ceff05d",
                    "name": "ceph",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 1144077
                },
                {
                    "vg": "os",
                    "type": "pv",
                    "lvm_meta_size": 0,
                    "size": 0
                }
            ],
            "type": "disk",
            "id": "disk/by-path/pci-0000:03:00.0-scsi-0:0:4:0",
            "size": 1144641
        },
        {
            "name": "sdf",
            "extra": [
                "disk/by-id/wwn-0x5000c500724bebdf",
                "disk/by-id/scsi-35000c500724bebdf"
            ],
            "free_space": 0,
            "volumes": [
                {
                    "type": "boot",
                    "size": 300
                },
                {
                    "mount": "/boot",
                    "size": 200,
                    "type": "raid",
                    "file_system": "ext2",
                    "name": "Boot"
                },
                {
                    "type": "lvm_meta_pool",
                    "size": 64
                },
                {
                    "partition_guid": "45b0969e-9b03-4f30-b4c6-b4b80ceff106",
                    "name": "cephjournal",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 0
                },
                {
                    "partition_guid": "4fbd7e29-9d25-41b8-afd0-062c0ceff05d",
                    "name": "ceph",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 1144077
                },
                {
                    "vg": "os",
                    "type": "pv",
                    "lvm_meta_size": 0,
                    "size": 0
                }
            ],
            "type": "disk",
            "id": "disk/by-path/pci-0000:03:00.0-scsi-0:0:5:0",
            "size": 1144641
        },
        {
            "name": "sdg",
            "extra": [
                "disk/by-id/wwn-0x5000c5007143fa1b",
                "disk/by-id/scsi-35000c5007143fa1b"
            ],
            "free_space": 0,
            "volumes": [
                {
                    "type": "boot",
                    "size": 300
                },
                {
                    "mount": "/boot",
                    "size": 200,
                    "type": "raid",
                    "file_system": "ext2",
                    "name": "Boot"
                },
                {
                    "type": "lvm_meta_pool",
                    "size": 64
                },
                {
                    "partition_guid": "45b0969e-9b03-4f30-b4c6-b4b80ceff106",
                    "name": "cephjournal",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 0
                },
                {
                    "partition_guid": "4fbd7e29-9d25-41b8-afd0-062c0ceff05d",
                    "name": "ceph",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 1144077
                },
                {
                    "vg": "os",
                    "type": "pv",
                    "lvm_meta_size": 0,
                    "size": 0
                }
            ],
            "type": "disk",
            "id": "disk/by-path/pci-0000:03:00.0-scsi-0:0:6:0",
            "size": 1144641
        },
        {
            "name": "sdh",
            "extra": [
                "disk/by-id/wwn-0x5000c500724c3b1f",
                "disk/by-id/scsi-35000c500724c3b1f"
            ],
            "free_space": 0,
            "volumes": [
                {
                    "type": "boot",
                    "size": 300
                },
                {
                    "mount": "/boot",
                    "size": 200,
                    "type": "raid",
                    "file_system": "ext2",
                    "name": "Boot"
                },
                {
                    "type": "lvm_meta_pool",
                    "size": 64
                },
                {
                    "partition_guid": "45b0969e-9b03-4f30-b4c6-b4b80ceff106",
                    "name": "cephjournal",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 0
                },
                {
                    "partition_guid": "4fbd7e29-9d25-41b8-afd0-062c0ceff05d",
                    "name": "ceph",
                    "mount": "none",
                    "disk_label": null,
                    "type": "partition",
                    "file_system": "none",
                    "size": 1144077
                },
                {
                    "vg": "os",
                    "type": "pv",
                    "lvm_meta_size": 0,
                    "size": 0
                }
            ],
            "type": "disk",
            "id": "disk/by-path/pci-0000:03:00.0-scsi-0:0:7:0",
            "size": 1144641
        },
        {
            "_allocate_size": "min",
            "label": "Base System",
            "min_size": 42252,
            "volumes": [
                {
                    "mount": "/",
                    "size": 38156,
                    "type": "lv",
                    "name": "root",
                    "file_system": "ext4"
                },
                {
                    "mount": "swap",
                    "size": 4096,
                    "type": "lv",
                    "name": "swap",
                    "file_system": "swap"
                }
            ],
            "type": "vg",
            "id": "os"
        }
    ]
}
"""

# pm = pmanager.PManager(data)
# pm.eval()
# print pm.expose()

pm = pmanager.PreseedPManager(data)
pm.eval()

print "====== early"
print pm.expose_early()
print "====== disks"
print pm.expose_disks()
print "====== recipe"
print pm.expose_recipe()
print "====== late"
print pm.expose_late()

# for line in pm.expose_late().split('\n'):
#     if re.search(ur'^(parted|pvcreate|vgcreate|lvcreate|mkfs)', line):
#         print line

