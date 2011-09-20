require 'rubygems'
require 'sshgw/version'
require 'sshgw/arguments'
require 'sshgw/host'
require 'sshgw/user'
require 'highline/import' # ask("...")

module Sshgw
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


