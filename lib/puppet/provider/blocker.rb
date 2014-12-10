class Puppet::Provider::Blocker < Puppet::Provider

  #
  # some of this code is borrowed from the Puppet exec type
  #
  def block_until_ready(
    tries = resource[:tries],
    try_sleep = resource[:try_sleep],
    &block
  )
    tries.times do |try|
      debug("Blocker: try #{try+1}/#{tries}") if tries > 1
      return true if yield
      if try_sleep > 0 and tries > 1
        sleep try_sleep
      end
    end
    return false
  end
end
