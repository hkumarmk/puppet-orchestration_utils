require 'jiocloud/utils'
include Jiocloud::Utils
Puppet::Type.type(:consul_session).provide(
  :default
) do

  def exists?
    sessions = getSession({:name => resource[:name]})
    sessions.nil? ? raise(Puppet::Error,"Failed to get data from consul") : ! sessions.empty?
  end

  def create
    createSession(resource[:name],
      {
          :lockdelay => resource[:lockdelay],
          :node      => resource[:node],
          :checks    => resource[:checks],
      }
    )
  end

  def destroy
    deleteSession(resource[:name], resource[:node])
  end

end
