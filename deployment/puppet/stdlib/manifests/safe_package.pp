define safe_package (
) {
  if !defined(Package[$name]) {
    package { $name: }
  }
}
