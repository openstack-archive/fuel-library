include ::openstack_tasks::murano::db

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server
class murano::api {}
include murano::api
include ::osnailyfacter::override_resources
