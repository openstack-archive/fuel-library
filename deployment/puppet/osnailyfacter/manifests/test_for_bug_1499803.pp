notice('MODULAR:test_for_bug_1499803.pp')

class { 'osnailyfacter::test_for_bug_1499803':
  test  => hiera_array('test_roles', ['80', '8888']),
}

