require 'rubygems'
require 'lib/sshgw/version'
require 'lib/sshgw/arguments'
require 'net/ssh'
require 'net/scp'
require 'highline/import' # ask("...")

module Sshgw
  class User
    attr_accessor :name, :ssh_path
    def initialize(name)
      @name = name
      # TODO paths to define
      @home_path = "/home/#{@name}"
      @ssh_path = "#{@home_path}/.ssh"
      @key_path = "#{@ssh_path}/id_rsa.pub"
      @authorized_key_path = "#{@ssh_path}/authorized_key"
    end

    def ssh=ssh
      @ssh = ssh
    end

    def key
      # Return the user's key
      "THE PUBLIC KEY IS HERE"
    end

    def authorized_key
      # Return the user's authorized_key file content
      c=""
      begin
        c = @ssh.scp.download! @authorized_key_path
      rescue
        puts "#{@authorized_key_path} does not exist!"
      end  
      c
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
        @gw_user = User.new @internal_host.name
      end
    end
    def put(file,dir)
      # Put file in dir
    end
    def append_to_authorized_key
      puts "Adding local user #{local_user.name}'s key to #{gw_user.name} authorized_key file."
      #puts "Public key for #{local_user.name} : #{local_user.key}"
      #puts "#{gw_user.name}'s authorized_key content : #{gw_user.authorized_key}"

      content = "#{gw_user.authorized_key}\ncommand='ssh -t #{internal_host.local_user.name}@#{internal_host.name}' #{local_user.key}"
      puts content
      #k = ""
      #File.open local_user.key do |file|
      #  k+=file.read
      #end
      #f = File.open '/tmp/#{gw_user.name}','w'
      #f.write "command='ssh -t #{internal_host.local_user.name}@#{internal_host.name}' #{k}"
      #f.close
      #to_append = ""
      #File.open '/tmp/#{gw_user.name}' do |file|
      #  to_append+=file.read
      #end
      
      #@ssh.scp.upload! local_user.key, "#{gw_user.home}/#{local_user.name}"
      #@ssh.exec!("chown #{gw_user.name}:#{gw_user.name} #{gw_user.home}/#{local_user.name}")
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

  def self.run
    # TODO : Add authors here
    puts "sshgw version : #{Sshgw::VERSION}"
    options = Sshgw::parse(ARGV)
    gw_host = Sshgw::Host.new options[:gwhost], options[:user], options[:internalhost], options[:internaluser]
    puts "Create #{gw_host.gw_user.name} user on #{gw_host.name},"
    puts "then add #{gw_host.local_user.name}'s public key to #{gw_host.gw_user.name}@#{gw_host.name}:#{gw_host.gw_user.authorized_key} with the command option :"
    puts "command='ssh -t #{gw_host.internal_host.local_user.name}@#{gw_host.internal_host.name}' ssh-rsa..."
    puts "When done, add #{gw_host.gw_user.name}'s public key to #{gw_host.internal_host.local_user.name}@#{gw_host.internal_host.name}:#{gw_host.internal_host.local_user.authorized_key}."
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


