notice('MODULAR: test_for_bug_1499803.pp')

class { 'test_for_bug_1499903': 
  test  => hiera_array('test_roles'),
}

