#
# This define is only for "CFEngine compatability". It is only a light
# wrapper around the "line" define, which is equally dangerous, but at
# least named according to a proper resource model.
#
define append_if_no_such_line($file, $line) {
	line {
		$name:
			ensure => present,
			file => $file,
			line => $line;
	}
}

