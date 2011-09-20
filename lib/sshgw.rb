require 'rubygems'
require 'lib/sshgw/version'
require 'lib/sshgw/arguments'
require 'net/ssh'
require 'net/ssh/gateway'
require 'net/scp'
require 'highline/import' # ask("...")

module Sshgw
  class User
    attr_accessor :name, :ssh_path, :authorized_key_path
    def initialize(name)
      @name = name
      # TODO paths to define
      @home_path = "/home/#{@name}"
      @ssh_path = "#{@home_path}/.ssh"
      @key_path = "#{@ssh_path}/id_rsa.pub"
      @authorized_key_path = "#{@ssh_path}/authorized_key"
    end
    def key
      # Return the user's key
      "THE PUBLIC KEY IS HERE"
    end


  end

  class LocalUser < User
    def authorized_key
      # Return the user's authorized_key file content
      "THE CONTENT OF THE AUTHORIZED_KEY FILE"
    end

  end

  class RemoteUser < User
    def ssh=ssh
      @ssh = ssh
    end
    def authorized_key
      # Return the user's authorized_key file content
      c=""
      begin
        c = @ssh.scp.download! @authorized_key_path
      rescue
        puts "#{@authorized_key_path} does not exist!"
        @ssh.exec!("touch #{@authorized_key_path}")
        @ssh.exec!("chown #{@name}:#{@name} #{@authorized_key_path}")
        c = @ssh.scp.download! @authorized_key_path
      end  
    end

  end


  class Host
    attr_reader :name, :local_user, :internal_host, :gw_user
    def initialize(name_or_ip, local_user_name, internal_host = nil, internal_user_name = nil)
      @name = name_or_ip
      @local_user = LocalUser.new local_user_name
      # ssh object to handle connections
      @ssh = nil
      if internal_host && internal_user_name
        # We are the gw_host
        @internal_host = Host.new internal_host, internal_user_name
        @gw_user = RemoteUser.new @internal_host.name
      end
    end

    def append_to_authorized_key
      puts "Adding local user #{local_user.name}'s key to #{gw_user.name} authorized_key file."

      content = "#{gw_user.authorized_key}\ncommand='ssh -t #{internal_host.local_user.name}@#{internal_host.name}' #{local_user.key}"
      puts "New content :"
      puts content
      password = ask("Enter root password for #{internal_host.name}") { |q| q.echo = "*" }
      @ssh = Net::SSH.start @internal_host.name, 'root', :password => password
    end

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
      @ssh.close if @ssh
    end

    def create_user
      puts "Creating #{gw_user.name}"
      @ssh.exec!("useradd -m #{gw_user.name}")
      @ssh.exec!("mkdir #{gw_user.ssh_path}")
      @ssh.exec!("chown #{gw_user.name}:#{gw_user.name} #{gw_user.ssh_path}")
      @ssh.exec!("chmod 700 #{gw_user.ssh_path}")
      gw_user.ssh = @ssh
    end
  end

  class RemoteHost < Host
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

    def hostname
    end

  end

  def self.run
    # TODO : Add authors here
    puts "sshgw version : #{Sshgw::VERSION}"
    options = Sshgw::parse(ARGV)
    gw_host = Sshgw::Host.new options[:gwhost], options[:user], options[:internalhost], options[:internaluser]
    puts "Create #{gw_host.gw_user.name} user on #{gw_host.name},"
    puts "then add #{gw_host.local_user.name}'s public key to #{gw_host.gw_user.name}@#{gw_host.name}:#{gw_host.gw_user.authorized_key_path} with the command option :"
    puts "command='ssh -t #{gw_host.internal_host.local_user.name}@#{gw_host.internal_host.name}' ssh-rsa..."
    puts "When done, add #{gw_host.gw_user.name}'s public key to #{gw_host.internal_host.local_user.name}@#{gw_host.internal_host.name}:#{gw_host.internal_host.local_user.authorized_key_path}."
    rep = ask("Are you ok with this ? (y/n)")
    if rep == 'y' or rep =='Y'
      gw_host.connect
      gw_host.create_user
      gw_host.append_to_authorized_key
    else
      puts "Ok, bye!"
      exit
    end
    gw_host.close
  end

end


