node 'puppet' {
  include ::ntp
}

node 'control' {
  include ::havana::role::swiftcontroller
}

node 'storage' {
  include ::havana::role::storage
}

node 'network' {
  include ::havana::role::network
}

node 'compute' {
  include ::havana::role::compute
}

node 'swiftstore1' {
  class { '::havana::role::swiftstorage':
    zone => '1'
  }
}

node 'swiftstore2' {
  class { '::havana::role::swiftstorage':
    zone => '2'
  }
}

node 'swiftstore3' {
  class { '::havana::role::swiftstorage':
    zone => '3'
  }
}

node 'tempest' {
  include ::havana::role::tempest
}

