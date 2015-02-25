##
# facter to acquire lock
##
require 'jiocloud/utils'
include Jiocloud::Utils

hostname = Facter.value(:hostname)

##
# getNodeSessionNames may fail if consul is not setup or if consul is down, and
# this failure should not fail the facter as puppet shall have code to
# setup/correct consul.
##
begin
  sessions = getNodeSessionNames(hostname)
rescue
  true
end

##
# Sessions can be nil if consul is down or not setup currently (may be on first puppet
# run)
##
if ! sessions.nil?

  ##
  # We only care about sessions on specific format - we expect the valid session
  # in form <servicename>~<hostname>
  ##
  valid_sessions = sessions.select { |session| /~/.match(session) }

  ##
  # Iterate through all valid sessions and try to acquire a key,
  ##
  valid_sessions.each do |session|
    service,host = session.split('~')
    key =  "clusters/#{service}/leader"

    ##
    # Check if the key is locked and if not, just lock it. This check is only to
    # reduce PUT operations to consul as PUT can only be responded by consul
    # leader where GETs can be responded by any consul server if consul
    # configured appropriately.
    # leader is set if it is able to acquire the lock.
    # If somebody else acquire the lock, then set leader_name from the kv, else
    # set it as hostname.
    ##
    if getLockSession(key).empty?
      lock = createKV(key,hostname,{:acquire => session})
    else
      lock = false
    end

    leader = true if lock == true || (leader_name = getKvValue(key)) == hostname

    ##
    # This fact can be used in the puppet code to get the leader node name.
    ##
    Facter.add(:leader_node) do
      setcode do
        leader_name
      end
    end

    ##
    # This fact can be used to build hiera hierarcy and it give a ready to use
    # fact for other puppet code for the node's role in the cluster.
    ##
    Facter.add(:cluster_role) do
      setcode do
        if leader_name == hostname
          'leader'
        else
          'follower'
        end
      end
    end
  end
end
