Facter.add(:heartbeat_version) do
  setcode do
    if Facter::Core::Execution.which('heartbeat')
      heartbeat_version = Facter::Core::Execution.execute('heartbeat version 2>&1')
      %r{heartbeat version:?\s+v?([\w\.]+)}.match(heartbeat_version)[1]
    end
  end
end
