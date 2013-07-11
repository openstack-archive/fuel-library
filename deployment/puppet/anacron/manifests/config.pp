# Make periodic cron jobs run in the idle scheduling class to reduce
# their impact on other system activities.
class anacron::config {
	file { '/etc/anacrontab':
		source	=> 'puppet:///modules/anacron/anacrontab',
		ensure	=> file,
		owner	=> root,
		group	=> root,
		mode	=> 0644,
	}
}

