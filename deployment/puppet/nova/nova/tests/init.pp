stage { 'repo-setup':
  before => Stage['main'],
}
class { ['apt', 'nova::repo']: 
  stage => 'repo-setup',
}
class { 'nova': }
