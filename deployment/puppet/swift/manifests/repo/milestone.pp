#
# sets up the swift milestone ppa
#
class swift::repo::trunk {
  apt::ppa { 'ppa:swift-core/milestone': }
}
