# not a doc string

define cluster::corosync::cs_with_service (
  $first,
  $second,
  $cib = undef,
  $score = "INFINITY",
  $order = true,
  )
{
  cs_colocation { "${second}-with-${first}":
    ensure     => present,
    cib        => $cib,
    primitives => [$second, $first],
    score      => $score,
  }

  if $order {
    cs_order { "${second}-after-${first}":
      ensure   => present,
      cib      => $cib,
      first    => $first,
      second   => $second,
      score    => $score,
      require  => Cs_colocation["${second}-with-${first}"]
    }
  }

}