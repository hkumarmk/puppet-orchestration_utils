require 'base64'
require 'jiocloud/utils'
include Jiocloud::Utils

Puppet::Type.type(:consul_kv_mysql_slave_update).provide(
  :default,
) do

  # Without initvars commands won't work.
  initvars
  commands :mysql      => 'mysql'

  # Optional defaults file
  def self.defaults_file
    if File.file?("#{Facter.value(:root_home)}/.my.cnf")
      "--defaults-extra-file=#{Facter.value(:root_home)}/.my.cnf"
    else
      nil
    end
  end

  def kvurl
    'http://localhost:8500/v1/kv'
  end

  def defaults_file
    self.class.defaults_file
  end

  def masterdata
    kv = getKV(kvName)
    return [Base64.decode64(kv['Value']),kv['Flags']]
    mysql(defaults_file, '-NBe', "SHOW MASTER STATUS").chomp.split("\t")
  end

  def kvName
    "services/#{resource[:name]}/mysql/masterdata"
  end

  def exists?
    if mysql(defaults_file, '-NBe', 'show slave status').empty?
      puts "empty"
      begin
        mysql(defaults_file, '-NBe', 'start slave')
      rescue Exception => e
        puts "in rescue"
        if e.message =~ /The server is not configured as slave/
          puts "got message"
          return false
        else
          raise(Puppet::Error,"Failed to connect to mysql")
        end
      end
      puts "out of rescue"
    end
    return true
  end

  def create
    puts "in create"
    master_data = masterdata
    mysql(defaults_file, '-NBe',"CHANGE MASTER TO
            MASTER_HOST=\'#{Facter.value(:leader_node)}\',
            MASTER_USER=\'#{resource[:repl_user]}\',
            MASTER_PASSWORD=\'#{resource[:repl_password]}\',
            MASTER_LOG_FILE=\'#{master_data[0]}\',
            MASTER_LOG_POS=#{masterdata[1]}
          ")
    mysql(defaults_file, '-NBe','start slave')
  end

  def destroy
    raise('Cannot destroy slave configuration')
  end

end
