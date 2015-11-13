notice('MODULAR: test_for_bug_1499803.pp')

class { 
  test  => hiera_array('test_roles'),
}

