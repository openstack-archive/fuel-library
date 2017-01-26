class osnailyfacter::limits::limits {

  notice('MODULAR: limits/limits.pp')

  $roles             = hiera('roles')
  $limits            = hiera('limits', {})
  $general_mof_limit = pick($limits['general_mof_limit'], '102400')

  limits::limits{'*/nofile':
    hard => $general_mof_limit,
    soft => $general_mof_limit,
  }

  limits::limits{'root/nofile':
    hard => $general_mof_limit,
    soft => $general_mof_limit,
  }
}
