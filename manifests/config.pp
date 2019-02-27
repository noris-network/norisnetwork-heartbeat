# heartbeat::config
# @api private
#
# @summary It configures the heartbeat shipper
class heartbeat::config {
  $heartbeat_bin = '/usr/share/heartbeat/bin/heartbeat'

  $validate_cmd = $heartbeat::disable_configtest ? {
    true => undef,
    default => "${heartbeat_bin} test config -c %",
  }

  $heartbeat_config = delete_undef_values({
    'name'                      => $heartbeat::beat_name ,
    'fields_under_root'         => $heartbeat::fields_under_root,
    'fields'                    => $heartbeat::fields,
    'xpack'                     => $heartbeat::xpack,
    'tags'                      => $heartbeat::tags,
    'queue'                     => $heartbeat::queue,
    'logging'                   => $heartbeat::logging,
    'output'                    => $heartbeat::outputs,
    'processors'                => $heartbeat::processors,
    'heartbeat'                 => {
      'monitors'                 => $heartbeat::monitors,
    },
  })

  file { '/etc/heartbeat/heartbeat.yml':
    ensure       => $heartbeat::ensure,
    owner        => 'root',
    group        => 'root',
    mode         => $heartbeat::config_file_mode,
    content      => inline_template('<%= @heartbeat_config.to_yaml()  %>'),
    validate_cmd => $validate_cmd,
  }
}
