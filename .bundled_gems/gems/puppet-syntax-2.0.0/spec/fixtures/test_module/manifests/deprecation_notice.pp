node test inherits default {
  import 'pass.pp'
  notify { 'this should give a deprecation notice':
    message => 'inheritance is gone in the future parser',
  }
}
