#
# sets up the swift trunk ppa
#
class swift::repo::trunk {
  apt::ppa { 'ppa:swift-core/trunk': }
}
