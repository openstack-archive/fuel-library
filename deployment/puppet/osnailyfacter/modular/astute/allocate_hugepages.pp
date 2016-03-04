notice('MODULAR: allocate_hugepages.pp')

$hugepages = hiera_array('hugepages', false)

if $hugepages {
  osnailyfacter::allocate_hugepages { $hugepages: }
}
