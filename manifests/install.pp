# heartbeat::install
# @api private
#
# @summary It installs the heartbeat package
class heartbeat::install {
  case $heartbeat::ensure {
    'present': {
      $package_ensure = $heartbeat::package_ensure
    }
    default: {
      $package_ensure = $heartbeat::ensure
    }
  }
  package{'heartbeat-elastic':
    ensure => $package_ensure,
  }
}
