include ::l23network::params

# this is a workaround for run spec tests not only on Linux platform
if $::l23network::params::network_manager_name != undef {
  Package<| title == $::l23network::params::network_manager_name |> { provider => apt }
}
###