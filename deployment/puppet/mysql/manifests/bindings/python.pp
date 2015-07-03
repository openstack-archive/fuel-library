# Class: mysql::bindings::python
#
# This class installs the python libs for mysql.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mysql::bindings::python(
) {
  include ::mysql::python
}
