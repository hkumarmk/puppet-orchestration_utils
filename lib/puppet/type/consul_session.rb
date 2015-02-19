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
  end

  newparam(:lockdelay) do
    desc 'Length of the lock delay in seconds'
    defaultto 15
    munge do |v|
      Integer(v)
    end
  end

  newparam(:checks, :array_matching => :all) do
    desc 'List of checks. Includes serfhealth by default'
    defaultto ['serfHealth']
  end
end
