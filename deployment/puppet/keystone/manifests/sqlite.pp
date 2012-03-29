class keystone::sqlite(
  $idle_timeout = 200
) {
  keystone::config { 'sql':
    content => inline_template('
[sql]
connection = sqlite:////var/lib/keystone/keystone.db
idle_timeout = <%= idle_timeout %>
'),
    order => '02',
  }
}
