require 'rubygems'
require 'lib/sshgw/version'
require 'lib/sshgw/arguments'
require 'net/ssh'
require 'highline/import' # ask("...")

module Sshgw
  class User
    attr_accessor :name, :authorized_key
    def initialize(name)
      @name = name
      # TODO paths to define
      @authorized_key = "/home/#{name}/.ssh/authorized_key"
    end

  end
  class Host
    attr_reader :name, :local_user, :internal_host, :gw_user
    def initialize(name_or_ip, local_user_name, internal_host = nil, internal_user_name = nil)
      @name = name_or_ip
      @local_user = User.new local_user_name
      # ssh object to handle connections
      @ssh = nil
      if internal_host && internal_user_name
        # We are the gw_host
        @internal_host = Host.new internal_host, internal_user_name
        @gw_user = User.new @local_user.name + "-" + @internal_host.name
      end
    end
    def put(file,dir)
      # Put file in dir
    end
    def append_to_authorized_key(user, key)
      puts "Append key to authorized_key file!"
      puts "From local user #{user} to #{user}-#{@internal_host.name}:#{@authorized_key}"
    end

    def connect(password)
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
      @ssh.exec!("hostname")
    end
  end

  def self.run
    # TODO : Add authors here
    puts "sshgw version : #{Sshgw::VERSION}"
    options = Sshgw::parse(ARGV)
    gw_host = Sshgw::Host.new options[:gwhost], options[:user], options[:internalhost], options[:internaluser]
    puts "Create #{gw_host.gw_user.name} on #{gw_host.name},"
    puts "then add #{gw_host.local_user.name}'s public key to #{gw_host.gw_user.name}@#{gw_host.name}:#{gw_host.gw_user.authorized_key} with the command option :"
    puts "command='ssh -t #{gw_host.internal_host.local_user.name}@#{gw_host.internal_host.name}' ssh-rsa..."
    puts "When done, add #{gw_host.gw_user.name}'s public key to #{gw_host.internal_host.local_user.name}@#{gw_host.internal_host.name}:#{gw_host.internal_host.local_user.authorized_key}."
    rep = ask("Are you ok with this ? (y/n)")
    if rep == 'y' or rep =='Y'
      root_password = ask("Enter root password for #{gw_host.name}") { |q| q.echo = "*" }
      gw_host.connect(root_password)
      puts "Create #{gw_host.gw_user.name}"
      puts gw_host.create_user
      gw_host.append_to_authorized_key(options[:user], "the key")
      gw_host.close
    else
      puts "Ok, bye!"
      exit
    end
  end

end


