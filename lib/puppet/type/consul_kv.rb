Puppet::Type.newtype(:consul_kv) do

  @doc = <<-'EOD'
  Consul Key/value pair operations (Create, change, delete).
  e.g
  Add a key/value pair or change value of a key

  consul_kv{'foo/bar': value => 'baz'}

  Above code will create a key in consul named 'foo/bar' with value 'baz' if it
doesn't exist. If the key exists with different value, it will be changed.
  EOD

  ensurable

  newparam(:name, :namevar => true) do
    desc  'consul kv path. This is a relative path after /v1/kv.
    e.g setting key foo/bar will create the key under /v1/kv/foo/bar.'
  end

  newparam(:url) do
    desc 'Consul url to use'
    defaultto 'http://localhost:8500/v1/kv'
  end

  newproperty(:acquire) do
    desc 'Session name to acquire the lock'
  end

  newproperty(:release) do
    desc 'Release existing session or not, It takes three possible values,
      Yes - release any existing session lock
      No  - It is same as not setting this property
      <session name>  - Name of the session to be tried, if any other session is
locked, this will be ignored and nothing will happen'
    munge do |v|
      if v.match(/(yes)|(no)/i)
        v.capitalize
      end
    end
  end

  newparam(:node) do
    desc 'optional node name to make sure only lock the session owned by a node'
  end

  newparam(:cas) do
    desc 'convert put operations to check-and-set operations. The value is a
      number, if the value is 0, consul will only put the keyif it does not already
      exists, if its non-zero, then the key is only set if index matches modifyindex
      of that key'
    newvalues(/\d+/)
  end

  newparam(:flags) do
    desc 'An arbitrary number which can be used by applications'
    newvalues(/\d+/)
  end

  newproperty(:value) do
    desc 'Value to set'
  end

  validate do
    raise(Puppet::Error, 'Value should be set') unless self[:value]
    raise(Puppet::Error, 'Both acquire and release cannot be specified at a time') if self[:acquire] && self[:release]
  end

end
