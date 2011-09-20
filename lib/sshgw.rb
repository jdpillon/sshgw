require 'rubygems'
require 'sshgw/version'
require 'sshgw/arguments'
require 'net/ssh'
require 'net/ssh/gateway'
require 'net/scp'
require 'highline/import' # ask("...")

module Sshgw
  class User
    attr_accessor :name, :ssh_path, :authorized_keys_path
    def initialize(name)
      @name = name
      # TODO paths to define
      @home_path = "/home/#{@name}"
      @ssh_path = "#{@home_path}/.ssh"
      @key_path = "#{@ssh_path}/id_rsa.pub"
      @authorized_keys_path = "#{@ssh_path}/authorized_keys"
    end
    def key
      # Return the user's key
      "THE PUBLIC KEY IS HERE"
    end


  end

  class LocalUser < User
    def key
      # Return the user's key file content
      key = ""
      File.open @key_path do |file|
        key+=file.read
      end
    end

  end

  class RemoteUser < User
    def ssh=ssh
      @ssh = ssh
    end
    def authorized_keys=(content)
      # TODO : get random file name
      file = File.open '/tmp/a','w'
      file.write content
      file.close
      @ssh.scp.upload! '/tmp/a', @authorized_keys_path
    end
    def authorized_keys
      # Return the user's authorized_keys file content
      c=""
      begin
        c = @ssh.scp.download! @authorized_keys_path
      rescue
        puts "#{@authorized_keys_path} does not exist!"
        @ssh.exec!("touch #{@authorized_keys_path}")
        @ssh.exec!("chown #{@name}:#{@name} #{@authorized_keys_path}")
        c = @ssh.scp.download! @authorized_keys_path
      end  
    end

  end


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
    def connect
      puts "Connected to local host"
    end
    def exec(cmd)
      system(cmd)
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
        puts ssh.exec!(cmd)
      end
    end
    def create_user
      puts "Creating #{user.name}"
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
    def connect
      @password = ask("Enter root password for #{name}") { |q| q.echo = "*" }
    end
  end

  def self.append_user_key_to_authorized_keys_file(from, to)
    puts "Adding local user #{from.user.name}'s key to #{to.user.name} authorized_keys file."

    content = "#{to.user.authorized_keys}\ncommand=\"ssh -t #{to.remote_host.user.name}@#{to.remote_host.name}\" #{from.user.key}\n"
    to.user.authorized_keys=content
  end

  def self.run
    options = Sshgw::parse(ARGV)
    # TODO : Add authors here
    puts "sshgw version : #{Sshgw::VERSION}"

    local_host                = LocalHost.new 'localhost', options[:user]
    gateway_host              = GatewayHost.new options[:gwhost], options[:internalhost]
    gateway_host.remote_host  = RemoteHost.new options[:internalhost], options[:internaluser] 

    #gw_host = Sshgw::Host.new options[:gwhost], options[:user], options[:internalhost], options[:internaluser]
    puts "Create #{gateway_host.user.name} user on #{gateway_host.name},"
    puts "then add #{local_host.user.name}'s public key to #{gateway_host.user.name}@#{gateway_host.name}:#{gateway_host.user.authorized_keys_path} with the command option :"
    puts "command='ssh -t #{gateway_host.remote_host.user.name}@#{gateway_host.remote_host.name}' ssh-rsa..."
    puts "When done, add #{gateway_host.user.name}'s public key to #{gateway_host.remote_host.user.name}@#{gateway_host.remote_host.name}:#{gateway_host.remote_host.user.authorized_keys_path}."
    rep = ask("Are you ok with this ? (y/n)")
    

    if rep == 'y' or rep =='Y'
      gateway_host.connect
      gateway_host.create_user
      append_user_key_to_authorized_keys_file(local_host,gateway_host)
    else
      puts "Ok, bye!"
      exit
    end
    gateway_host.close
  end

end


