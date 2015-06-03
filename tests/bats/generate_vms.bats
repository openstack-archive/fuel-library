#!/usr/bin/env bats
# For testing use  bats framework
# https://github.com/sstephenson/bats

gvs="$BATS_TEST_DIRNAME/../../deployment/puppet/osnailyfacter/modular/cluster/generate_vms.sh"

load "$gvs"
libvirt_template="$BATS_TMPDIR/libvirt.xml"
vm_name="1_vm"

@test "Check help message" {
  run usage
  [ $status -eq 1 ]
}

@test "Check setting default CPU when CPU not set" {
  echo '<domain type="kvm">
  <vcpu placement="static"></vcpu>
  </domain>' > ${libvirt_template}

  run verify_cpu $vm_name $libvirt_template
  [ "${lines[0]}" = "No cpu cores, setting to default" ]
}

@test "Check setting default CPU when CPU set" {
  echo '<domain type="kvm">
  <vcpu placement="static">10</vcpu>
  </domain>' > ${libvirt_template}

  run verify_cpu $vm_name $libvirt_template
  [ "${lines[0]}" = "" ]
}

@test "Check setting default MEM when MEM not set" {
  echo '<domain type="kvm">
  <memory unit="GiB"></memory>
  </domain>' > ${libvirt_template}

  run verify_mem $vm_name $libvirt_template
  [ "${lines[0]}" = "No memory set, setting to default" ]
}

@test "Check setting default MEM when MEM set" {
  echo '<domain type="kvm">
  <memory unit="GiB">10</memory>
  </domain>' > ${libvirt_template}

  run verify_mem $vm_name $libvirt_template
  [ "${lines[0]}" = "" ]
}

@test "Check unknown disk type" {
  echo '<domain type="kvm">
  <devices><disk type="fake" device="disk">
  </disk></devices>
  </domain>' > ${libvirt_template}

  run create_vm_disks $vm_name $libvirt_template
  [ "${lines[1]}" = "Unknown disk type, ignoring" ]
}

@test "Check missing disk" {
  echo '<domain type="kvm">
  <devices></devices>
  </domain>' > ${libvirt_template}

  run create_vm_disks $vm_name $libvirt_template
  [ "${lines[0]}" = "Disks for $vm_name, total number 0" ]
}

@test "Check missing disk type" {
  echo '<domain type="kvm">
  <devices><disk type="file" device="disk"><driver type="">
  </driver></disk></devices>
  </domain>' > ${libvirt_template}

  run create_vm_disks $vm_name $libvirt_template
  [ "${lines[2]}" = "Failed to get disk details, ignoring" ]
}

@test "Check missing disk file" {
  echo '<domain type="kvm">
  <devices><disk type="file" device="disk"><driver name="qemu" /><source file="">
  </source></disk></devices>
  </domain>' > ${libvirt_template}

  run create_vm_disks $vm_name $libvirt_template
  [ "${lines[2]}" = "Failed to get disk details, ignoring" ]
}

@test "Check disk creation when disk file already exists" {
  echo "<domain type='kvm'>
  <devices><disk type='file' device='disk'><driver name='qemu' type='qcow2' cache='writeback'/>
  <source file='${libvirt_template}'>
  </source></disk></devices>
  </domain>" > ${libvirt_template}

  run create_vm_disks $vm_name $libvirt_template
  [ "${lines[2]}" = "Disk file already exists, ignoring" ]
}
