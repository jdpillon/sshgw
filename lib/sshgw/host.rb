require 'net/ssh'
require 'net/ssh/gateway'
require 'net/scp'

module Sshgw
  class Host
    attr_reader :name, :user

    def connect
      password = ask("Enter root password for #{name}") { |q| q.echo = "*" }
      begin
        @ssh = Net::SSH.start @name, 'root', :password => password
        puts "Connected to #{@name} as root"
        rescue
          puts "Unable to connect to #{@name}"
          exit
      end
    end

    def close
      puts "Closing connection to #{@name}"
      @gateway.shutdown!
      #@ssh.close if @ssh
    end

  end

  # The local host as localhost
  class LocalHost < Host
    def initialize(name_or_ip, user_name)
      @name = name_or_ip
      @user = LocalUser.new user_name
      # ssh object to handle connections
    end
  end
  # The host used as ssh gateway
  class GatewayHost < Host
    attr_accessor :gateway, :remote_host
    def initialize(name_or_ip, user_name)
      @name = name_or_ip
      @user = RemoteUser.new user_name
    end

    def connect
      @password = ask("Enter root password for #{name}") { |q| q.echo = "*" }
      begin
        @gateway = Net::SSH::Gateway.new @name, 'root', :password => @password
        puts "Connected to #{@name} as root"
        rescue
          puts "Unable to connect to #{@name}"
          exit
      end
    end
    

    def exec(cmd, host = 'localhost')
      @gateway.ssh(host,'root',:password => @password) do |ssh|
        ssh.exec!(cmd)
      end
    end
    def create_user
      puts "Creating user #{user.name} on #{name}"
      exec("useradd -m #{user.name}")
      exec("mkdir #{user.ssh_path}")
      exec("chown #{user.name}:#{user.name} #{user.ssh_path}")
      exec("chmod 700 #{user.ssh_path}")
      user.ssh = Net::SSH.start @name, 'root', :password => @password
    end
  end
  # The host we want to reach through the ssh gateway
  class RemoteHost < Host
    def initialize(name_or_ip, user_name)
      @name = name_or_ip
      @user = RemoteUser.new user_name
    end
  end
end
