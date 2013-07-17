# Class: limits
#
# This module manages limits
#
# Parameters:
#    $title - should be of the form domain/(hard|soft)/item
#    $value - value of limit
#
# Actions:
#    creates a fragment fil corresponing to each limit entry  
define limits::fragment (
  $value
) {

  include limits
  if ( ! ($title =~ /\S+\/(hard|soft)\/\S+/)) {
    fail("invalid limits format: ${title}")
  }
  $file_name = regsubst($title, '\/', '_', 'G')

  file { "${limits::fragments_dir}/${file_name}.txt":
    content => inline_template("<%= title.gsub('/', ' ') %> <%= value %>\n"),
    before => Exec['cp_limits']
  }
}
