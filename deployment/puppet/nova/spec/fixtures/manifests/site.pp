node default {}

node 'test-001.example.org' {
  include ::nova
  include ::nova::consoleauth
  include ::nova::spicehtml5proxy
}
