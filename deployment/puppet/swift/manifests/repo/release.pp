#
# sets up the swift trunk ppa
#
class swift::repo::release {
  apt::ppa { 'ppa:swift-core/release': }
}
