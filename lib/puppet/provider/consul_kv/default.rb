require 'jiocloud/utils'
include Jiocloud::Utils
Puppet::Type.type(:consul_kv).provide(
  :default,
) do

  def kvurl
    resource[:url]
  end

  def lockSession
    @lock ||= getLockSession(resource[:name])
    return @lock
  end

  def releaseSession
    if resource[:release] == 'Yes'
      session = lockSession
      if session.nil? || session.empty?
        return nil
      end
      getSessionName({:id => lockSession})
    elsif resource[:release] == 'No' || resource[:release].nil?
      return nil
    else
      resource[:release]
    end
  end

  def exists?
    key = getKV(resource[:name])
    key.nil? ? raise(Puppet::Error,"Failed to get data from consul") : ! key.empty?
  end

  def create
    createKV(resource[:name],resource[:value],
      {
        :flags   => resource[:flags],
        :acquire => resource[:acquire],
        :release => releaseSession,
        :cas     => resource[:cas],
        :node    => resource[:node],
      }
    )
  end

  def destroy
    deleteKV(resource[:name])
  end

  def value
    getKvValue(resource[:name])
  end

  def value=(value)
    create
  end

  ##
  # acquire getter method make sure that setter will not be called if there any
  # lock already there - in fact since consul lock operation is idempotent
  # itself, we could just do an acquire operation, but Im just not doing it as
  # it will cause PUT (Write) operation everytime which I thought to be bit heavier than
  # get.
  #
  # TODO: The response for acquire should be noted and create a notice()
  # if it see somebody else locked it. This is to have cleaner puppet reports.
  ##
  def acquire
    lock = lockSession
    if lock
      return  resource[:acquire]
    else
      return false
    end
  end

  def acquire=(value)
    create
  end

  def release
    lock = lockSession
    # If release is no, then no action required
    if resource[:release] == 'No'
      return resource[:release]
    # if release is yes, then lock to be released if its locked with any
    # session.
    elsif resource[:release] == 'Yes' && lock
      return false
    # If release is the session name, then it only need to be released if the
    # lock is made on that session.
    elsif lock == resource[:release]
      return false
    # No action in any other situation
    else
      return resource[:release]
    end
  end

  def release=(value)
    create
  end

end
