#!/usr/bin/env bats
#

ocf_funcs="$BATS_TEST_DIRNAME/../../files/fuel-ha-utils/ocf/ocf-fuel-funcs"

load "${ocf_funcs}"

@test "Check validate_port(): without parameters" {
  run validate_port
  [ $status -eq 2 ]
}

@test "Check validate_port(): with port 0" {
  run validate_port 0
  [ $status -eq 1 ]
}

@test "Check validate_port(): with port 1" {
  run validate_port 1
  [ $status -eq 0 ]
}

@test "Check validate_port(): with port 65535" {
  run validate_port 65535
  [ $status -eq 0 ]
}

@test "Check validate_port(): with port 65536" {
  run validate_port 65536
  [ $status -eq 1 ]
}

@test "Check validate_port(): with alphanumeric parameter" {
  run validate_port aaa1
  [ $status -eq 1 ]
}
