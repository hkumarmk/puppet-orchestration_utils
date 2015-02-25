##
# Collection of methods to do consul operations
##

require 'json'
require 'net/http'
require 'uri'
require 'base64'

# Forward declaration
module Jiocloud; end

module Jiocloud::Utils

  ##
  # Connect to the url and create a uri and http object
  ##
  def connect(url)
    @uri = URI(url)
    @http = Net::HTTP.new(@uri.host, @uri.port)
  end

  ##
  # Do all get operations and parse the json body (consul return json body)
  # return empty value on 404 which happen when the object looking for does not
  # exist.
  ##
  def get(url)
    connect(url)
    path=@uri.request_uri
    req = Net::HTTP::Get.new(path)
    res = @http.request(req)
    if res.code == '200'
      return JSON.parse(res.body)
    elsif res.code == '404'
      return ''
    else
      raise("Uri: #{@uri.to_s} reutrned invalid return code #{res.code}")
    end
  end

  ##
  # Do PUT operations to consul url provided,
  # return true if body is empty - Consul return nothing on some PUT operations
  # Return the body if not empty, consul return id of the object some operations
  ##
  def put(url,body)
    connect(url)
    path = @uri.request_uri
    req = Net::HTTP::Put.new(path)
    req.body = body
    res = @http.request(req)
    if res.code == '200'
      if res.body.empty?
        return true
      else
        return res.body
      end
    else
      raise("Uri: #{@uri.to_s}/#{body} reutrned invalid return code #{res.code}")
    end
  end

  ##
  # Do Delete operations, return true on 200, return false on 404 and raise
  # exception on any other http return code
  ##
  def delete(url)
    connect(url)
    path = @uri.request_uri
    req = Net::HTTP::Delete.new(path)
    res = @http.request(req)
    if res.code == '404'
      return false # The url doesnt exists
    elsif res.code == '200'
      return true
    else
      raise("Uri: #{@uri.to_s} reutrned invalid return code #{res.code}")
    end
  end


  ##
  # method to return kv,session url which can be overrided on any child class
  ##
  def kvurl
    'http://localhost:8500/v1/kv'
  end

  def sessionurl
    'http://localhost:8500/v1/session'
  end

  ##
  # Check-and-Set for session.
  # I dont know this is required at all, and it may make sense to include node
  # arguments to getSessionID and This is not atomic, and in case session got
  # created simultaniously will cause multiple sessions with same name.
  # Just keeping it in case required.
  ##
  def casSession(name,args={})
    if getSessionID({:name => name}) == ''
      createSession(name,args)
    else
      true
    end
  end

  ##
  # Create consul session with the arguments provided. return  session id,  else
  # return false
  ##
  def createSession(name,args={})
    body_hash = {}
    body_hash['Name'] = name
    body_hash['LockDelay'] = args[:lockdelay] if args.key?(:lockdelay)
    body_hash['Node'] = args[:node] if args.key?(:node)
    body_hash['Checks'] = args[:checks] if args.key?(:checks)
    body = body_hash.to_json
    data = put(sessionurl + '/create',body)
    session = JSON.parse(data)
    if session.empty?
      return false
    else
      return session['ID']
    end
  end

  ##
  # Get session id
  ##
  def getSessionID(args={})
    @sessionID ||= getSession(args)['ID']
    return @sessionID
  end

  ##
  # Get session name
  ##
  def getSessionName(args={})
    return getSession(args)['Name']
  end

  ##
  # Get the session based on the arguments, and return  the session hash. It
  # will return empty hash in case session doesnt exist.
  ##
  def getSession(args = {})
    if args.key?(:id) && ! args[:id].nil?
      session = Jiocloud::Utils.get(sessionurl + '/info/' + args[:id])
    elsif args.key?(:name) && ! args[:name].nil?
      if args.key?(:node) && ! args[:node].nil?
        sessions = Jiocloud::Utils.get(sessionurl + '/node/' + args[:node])
      else
        sessions = Jiocloud::Utils.get(sessionurl + '/list')
      end
      session = sessions.select {|session| session['Name'] == args[:name]}
    end

    if session.empty?
      return {}
    elsif session.count > 1
      raise("Multiple matching (#{session.count}) Consul Sessions found for #{args[:name]}")
    else
      return session[0]
    end
  end

  ##
  # Delete a matching session with its name and optional node name
  ##
  def deleteSession(name,node=nil)
    Jiocloud::Utils.put(sessionurl + '/destroy/' + getSessionID({:name => name,:node => node}),'')
  end

  ##
  # return the session belonging to specified node
  ##
  def getNodeSessions(node)
    sessions = Jiocloud::Utils.get(sessionurl + '/node/' + node)
    return sessions
  end

  ##
  # Return an array of session names belonging to the specified node
  ##
  def getNodeSessionNames(node)
    sessions = getNodeSessions(node)
    return sessions.collect { |x| x['Name'] }
  end

  ##
  # Return array of session ids belonging to the specified node
  ##
  def getNodeSessionIDs(node)
    sessions = getNodeSessions(node)
    return sessions.collect { |x| x['ID'] }
  end

  ##
  # There are more parameters Create kv can accept, but now only required
  # parameters for sessions are added.
  ##
  def createKV(key,value,args={})
    url_params = []
    if args.key?(:acquire) && ! args[:acquire].nil?
      session_name = args[:acquire]
      node         = args[:node]
      session_id = getSessionID({:name => session_name, :node => node})
      url_params << 'acquire=' + session_id
    end

    if args.key?(:release) && ! args[:release].nil?
      session_name = args[:release]
      node         = args[:node]
      session_id = getSessionID({:name => session_name,:node => node})
      url_params << 'release=' + session_id
    end

    url_params << "flags=#{args[:flags]}" if args.key?(:flags) && ! args[:flags].nil?

    url_params << "cas=#{args[:cas]}" if args.key?(:cas) && ! args[:cas].nil?
    if url_params.empty?
      Jiocloud::Utils.put(kvurl + '/' + key,value)
    else
      Jiocloud::Utils.put(kvurl + '/' + key + '?' + url_params.join('&'),value)
    end
  end

  ##
  # Get ID of the session which is locked the key provided.
  # Return nil if the key is nil and there is no lock,
  # Return empty string if there is no matching KV.
  # Return Session ID when there is a lock
  ##
  def getLockSession(key)
    return nil if key.nil?
    kv = getKV(key)
    if kv.empty?
      return ''
    else
      return kv['Session']
    end
  end

  ##
  # Get Value of a consul key, return empty if non-exisistant key or empty value,
  # otherwise return decoded value
  ##
  def getKvValue(key)
    kv = getKV(key)
    if kv.empty?
      return ''
    else
      return Base64.decode64(kv['Value'])
    end
  end

  ##
  # Return whole Key object which includes the value, and other properties of
  # that key like name, value, locked session, flag etc.
  ##
  def getKV(key)
    kv = Jiocloud::Utils.get(kvurl + '/' + key)
    if kv.empty?
      return ''
    else
      return kv[0]
    end
  end

  ##
  # Delete a KV.
  ##
  def deleteKV(key)
    Jiocloud::Utils.delete(kvurl + '/' + key)
  end

end
