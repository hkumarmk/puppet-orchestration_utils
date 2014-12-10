Puppet::Type.newtype(:runtime_fail) do

  desc <<-'EOD'
  Fail the puppet execution on runtime. The problem with fail function is that
, as functions are evaluated on comple time, the execution will fail during that
time, so if the condition evaluates a resource which create on the same
role/node will cause the execution always fail as the puppet execution willl
never happen.
  EOD

  newparam(:message, :namevar => true) do
    desc 'The message to print on fail. Defaults to name'
  end

  newparam(:fail) do
    desc 'Whether to fail or not'
    defaultto true
  end

  newproperty(:ready) do
    defaultto true
  end

  validate do
    raise(Puppet::Error, 'Ready should not be set') unless self[:ready] == true
  end
end
