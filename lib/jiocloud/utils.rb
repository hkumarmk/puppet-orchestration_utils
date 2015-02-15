##
# Collection of methods to do consul operations
# The methods
#   return nil if url is not accessible, this will make sure facter which use
#     this code will not fail the puppet execution. (Do we need to handle all
#     excepions, rather than raising puppet::error?)
#   return true or data output if operations suceed
#   return false if operations failed
##

require 'json'
require 'net/http'
require 'uri'
require 'base64'

# Forward declaration
module Jiocloud; end

module Jiocloud::Utils

  def connect(url)
    @uri = URI(url)
    @http = Net::HTTP.new(@uri.host, @uri.port)
  end

  def get(url)
    connect(url)
    path=@uri.request_uri
    req = Net::HTTP::Get.new(path)
    begin
      res = @http.request(req)
    rescue
      return nil
    end
    if res.code == '200'
      return JSON.parse(res.body)
    elsif res.code == '404'
      return ''
    else
      raise(Puppet::Error,"Uri: #{@uri.to_s} reutrned invalid return code #{res.code}")
    end
  end

  def put(url,body)
    connect(url)
    path = @uri.request_uri
    req = Net::HTTP::Put.new(path)
    req.body = body
    begin
      res = @http.request(req)
    rescue
      return nil
    end
    if res.code == '200'
      if res.body.empty?
        return true
      else
        return res.body
      end
    else
      raise(Puppet::Error,"Uri: #{@uri.to_s}/#{body} reutrned invalid return code #{res.code}")
    end
  end

  def delete(url)
    connect(url)
    path = @uri.request_uri
    req = Net::HTTP::Delete.new(path)
    begin
      res = @http.request(req)
    rescue
      return nil
    end
    if res.code == '404'
      return false # The url doesnt exists
    elsif res.code == '200'
      return true
    else
      raise(Puppet::Error,"Uri: #{@uri.to_s} reutrned invalid return code #{res.code}")
    end
  end



  def kvurl
    'http://localhost:8500/v1/kv'
  end

  def sessionurl
    'http://localhost:8500/v1/session'
  end

  ##
  # Check-and-Set for session.
  ##
  def casSession(name,args={})
    if getSessionID(name) == ''
      createSession(name,args)
    else
      true
    end
  end

  def createSession(name,args={})
    body_hash = {}
    body_hash['Name'] = name
    body_hash['LockDelay'] = args['lockdelay'] if args.key?('lockdelay')
    body_hash['Node'] = args['node'] if args.key?('node')
    body_hash['Checks'] = args['node'] if args.key?('checks')
    body = body_hash.to_json
    data = put(sessionurl + '/create',body)
    if data.nil?
      return nil
    end
    session = JSON.parse(data)
    if session.empty?
      return false
    else
      return session['ID']
    end
  end

  def getSessionID(name)
    return getSession(name)['ID']
  end

  def getSession(name)
    sessions = get(sessionurl + '/list')
    if sessions.nil?
      return nil
    end
    session = sessions.select {|session| session['Name'] == name}
    if session.empty?
      return ''
    elsif session.count > 1
      raise(Puppet::Error,"Multiple matching (#{session.count}) Consul Sessions found for #{name}")
    else
      return session[0]
    end
  end

  def deleteSession(name)
    put(sessionurl + '/destroy/' + getSessionID(name),'')
  end

  ##
  # There are more parameters Create kv can accept, but now only required
  # parameters for sessions are added.
  ##

  def createKV(key,value,args={})
    url_params = []
    if args.key?('acquire')
      session_name = args['acquire']
      session_id = getSessionID(session_name)
      url_params << 'acquire=' + session_id
    end

    if args.key?('release')
      session_name = args['release']
      session_id = getSessionID(session_name)
      url_params << 'release=' + session_id
    end
    if url_params.empty?
      put(kvurl + '/' + key,value)
    else
      put(kvurl + '/' + key + '?' + url_params.join('&'),value)
    end
  end

  def getKV(key)
    key = get(kvurl + '/' + key)
    if key.nil?
      return nil
    elsif key.empty?
      return ''
    else
      return Base64.decode64(key[0]['Value'])
    end
  end

  def deleteKV(key)
    delete(kvurl + '/' + key)
  end

end
