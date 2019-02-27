# heartbeat::service
# @api private
#
# @summary It manages the heartbeat service
class heartbeat::service {
  if $heartbeat::ensure == 'present' {
    case $heartbeat::service_ensure {
      'enabled': {
        $service_status = 'running'
        $service_enabled = true
      }
      'disabled': {
        $service_status = 'stopped'
        $service_enabled = false
      }
      'running': {
        $service_status = 'running'
        $service_enabled = false
      }
      'unmanaged': {
        $service_status = undef
        $service_enabled = false
      }
      default: {}
    }
  }
  else {
    $service_status = 'stopped'
    $service_enabled = false
  }

  service {'heartbeat':
    ensure   => $service_status,
    enable   => $service_enabled,
    provider => $heartbeat::service_provider,
  }
}
