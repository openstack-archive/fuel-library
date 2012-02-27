#
# sets up the swift milestone ppa
#
class swift::repo::milestone {
  apt::ppa { 'ppa:swift-core/milestone': }
}
