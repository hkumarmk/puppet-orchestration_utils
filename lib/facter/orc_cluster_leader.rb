##
# facter to acquire lock
##
require 'jiocloud/utils'
include Jiocloud::Utils

hostname = Facter.value(:hostname)
sessions = getNodeSessionNames(hostname)
if ! sessions.nil?
  valid_sessions = sessions.select { |session| /~/.match(session) }

  valid_sessions.each do |session|
    service,host = session.split('~')
    key =  "clusters/#{service}/leader"
    leader = true if createKV(key,hostname,{'acquire' => session}) == true || (leader_name = getKV(key)) == hostname

    Facter.add(:leader) do
      setcode do
        if leader
          hostname
        else
          leader_name
        end
      end
    end

    Facter.add(:cluster_role) do
      setcode do
        if leader
          'leader'
        else
          'follower'
        end
      end
    end
  end
end
