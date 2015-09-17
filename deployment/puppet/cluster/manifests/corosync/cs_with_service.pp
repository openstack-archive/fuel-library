# not a doc string

#TODO (bogdando) move to extras ha wrappers
define cluster::corosync::cs_with_service (
  $first,
  $second,
  $score = 'INFINITY',
  $order = true,
  )
{
  pcmk_colocation { "${second}-with-${first}":
    ensure     => 'present',
    first      => $first,
    second     => $second,
    score      => $score,
  }

  if $order {
    pcmk_order { "${second}-after-${first}":
      ensure   => 'present',
      first    => $first,
      second   => $second,
      score    => $score,
      require  => Pcmk_colocation["${second}-with-${first}"]
    }
  }

}
