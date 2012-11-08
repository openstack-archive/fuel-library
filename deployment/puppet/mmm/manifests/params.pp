class mmm::params {
  
## DEFAULTS FOR VARIABLES USERS CAN SET
# (Here are set the defaults, provide your custom variables externally)
# (The default used is in the line with '')

  ## Is this a multi-mmm setup? this variable is needed to set to 
  ## true when multiple mmm clusters are monitored by a single mmm monitoring node 
  ## Example: $::mmm_multi_cluster_monitor = TRUE
  $multi_cluster_monitor = $::mmm_multi_cluster_monitor ? {
    ''      => FALSE,
    default => $::mmm_multi_cluster_monitor,
  }
  
}