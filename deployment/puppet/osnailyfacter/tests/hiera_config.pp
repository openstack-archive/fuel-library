hiera_config { 'test' :
  path             => '/tmp/hiera.yaml',
  hierarchy_bottom => ['bottom1', 'bottom2'],
  hierarchy_top    => ['top1','top2']
}
