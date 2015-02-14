Puppet::Type.newtype(:consul_session) do

  desc <<-'EOD'
  Create a consul session.
  EOD
  ensurable

  newparam(:name, :namevar => true) do
    desc 'Name of the session'
  end

  newparam(:node) do
    desc 'Name of the node for this session'
    defaultto Facter.value(:hostname)
    #defaultto 'derp'
  end

  newparam(:lockdelay) do
    desc 'Length of the lock delay in seconds'
    defaultto 15
    munge do |v|
      Integer(v)
    end
  end

  newparam(:checks) do
    desc 'List of checks. Includes serfhealth by default'
    defaultto ['serfHealth']
  end

  newparam(:url) do
    desc 'Consul url to use'
    defaultto 'http://localhost:8500/v1/session'
  end

  newparam(:tries) do
    desc 'The amount of times to retry before failing'
    defaultto 1
    munge do |v|
      Integer(v)
    end
  end
end
