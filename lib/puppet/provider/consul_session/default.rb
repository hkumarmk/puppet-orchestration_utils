require 'json'
require 'net/http'
require 'uri'
require 'base64'
Puppet::Type.type(:consul_session).provide(
  :default
) do

  def connect(url)
    @uri ||= URI(url)
    @http ||= Net::HTTP.new(@uri.host, @uri.port)
  end

  def self.instances
    @uri = URI('http://localhost:8500/v1/session')
    @http = Net::HTTP.new(@uri.host, @uri.port)

    path=@uri.request_uri + '/list'
    Puppet.debug("PATH: #{path}")
    req = Net::HTTP::Get.new(path)
    res = @http.request(req)

    if res.code == '200'
      sessions = JSON.parse(res.body)
    else
      sessions = []
    end
    sessions.collect do |session|
      new( :name => session["Name"],
           :lockdelay => Integer(session["LockDelay"]) / 1000000000, #nanoseconds
           :node => session["Node"],
           :ensure => :present,
           :checks => session["Checks"])
    end
  end

  ##
  # Find a session that matches our resource
  ##

  def getSession(url,name,node,lockdelay,checks)
    connect(url)
    path=@uri.request_uri + '/list'
    Puppet.debug("PATH: #{path}")
    req = Net::HTTP::Get.new(path)
    res = @http.request(req)

    if res.code == '200'
      sessions = JSON.parse(res.body)
    elsif res.code == '404'
      sessions = ''
    else
      raise(Puppet::Error,"Uri: #{@uri.to_s}/#{key} returned invalid return code #{res.code}")
    end

    match_sessions = sessions.select{ |s| s["Name"] == resource[:name] }
    if resource[:node]
      match_sessions = match_sessions.select{ |s| s["Node"] == resource[:node] }
    end
    if resource[:lockdelay]
      match_sessions = match_sessions.select{ |s| Integer(s["LockDelay"]) / 1000000000 == resource[:lockdelay] }
    end
    if resource[:checks]
      match_sessions = match_sessions.select{ |s| s["Checks"] == resource[:checks] }
    end
    if match_sessions.count > 1
      raise(Puppet::Error,"Multiple matching (#{match_sessions.count}) Consul Sessions found for #{resource[:name]}, unable to determine ID")
    elsif match_sessions.count < 1
      return nil
    else
      return match_sessions[0]
    end
  end

  def putSession(url,name,node,lockdelay,checks)
    connect(url)
    path = @uri.request_uri + '/create'
    req = Net::HTTP::Put.new(path)
    req.body = {
        "Name" => name,
        "LockDelay" => lockdelay,
        "Checks" => checks,
        "Node" => node
    }.to_json
    res = @http.request(req)
    if res.code != '200'
      raise(Puppet::Error,"Session #{name} create: invalid return code #{res.code} uri: #{@uri.to_s} body: #{req.body}")
    end
  end

  def destroySession(url,id)
    connect(url)
    path = @uri.request_uri + '/destroy/' + id
    req = Net::HTTP::PUT.new(path)
    res = @http.request(req)
    if res.code != '200'
      raise(Puppet::Error,"Session #{id} destroy: invalid return code #{res.code}")
    end
  end

  def exists?
    session = getSession(resource[:url], resource[:name], resource[:node], resource[:lockdelay], resource[:checks])
    if session
      Puppet.debug("Session existss: #{session}")
      return true
    else
      Puppet.debug("Session does not exist")
      return false
    end
  end

  def create
    putSession(resource[:url], resource[:name], resource[:node], resource[:lockdelay], resource[:checks])
  end

  def destroy
    session = getSession(resource[:url], resource[:name], resource[:node], resource[:lockdelay], resource[:checks])
    if session
      destroySession(resource[:url], session["ID"])
    else
      raise(Puppet::Error,"Couldn't find session to destroy")
    end
  end
end
