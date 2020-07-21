# heartbeat::config
# @api private
#
# @summary It configures the heartbeat shipper
class heartbeat::config {

  File {
    owner => $heartbeat::user,
    group => $heartbeat::group,
  }

  case $::kernel {
    'windows': {
      $heartbeat_bin = "${heartbeat::path_home}/heartbeat.exe"
    }
    default: {
      $heartbeat_bin = "${heartbeat::path_home}/heartbeat"
    }
  }

  $validate_cmd = $heartbeat::disable_configtest ? {
    true => undef,
    default => "${heartbeat_bin} test config -c %",
  }

  $heartbeat_config = delete_undef_values({
    'name'                      => $heartbeat::beat_name ,
    'fields_under_root'         => $heartbeat::fields_under_root,
    'fields'                    => $heartbeat::fields,
    'xpack'                     => $heartbeat::xpack,
    'monitoring'                => $heartbeat::monitoring,
    'tags'                      => $heartbeat::tags,
    'queue'                     => $heartbeat::queue,
    'logging'                   => $heartbeat::logging,
    'output'                    => $heartbeat::outputs,
    'processors'                => $heartbeat::processors,
    'setup'                     => $heartbeat::setup,
    'heartbeat'                 => {
      'monitors'                 => $heartbeat::monitors,
    },
  })

  file { "${heartbeat::path_config}/heartbeat.yml":
    ensure       => $heartbeat::ensure,
    mode         => $heartbeat::config_file_mode,
    content      => inline_template('<%= @heartbeat_config.to_yaml()  %>'),
    validate_cmd => $validate_cmd,
  }
}
