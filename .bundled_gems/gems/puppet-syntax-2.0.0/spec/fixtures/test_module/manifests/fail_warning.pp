class warning_puppet_module {
  notify { 'this should raise a warning':
    message => "because of \[\] escape characters",
  }
}
