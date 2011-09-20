require 'net/ssh'
require 'net/ssh/gateway'
require 'net/scp'

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
      File.open @key_path do |f|
        key+=f.read
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
        puts "#{@authorized_keys_path} does not exist yet!"
        @ssh.exec!("touch #{@authorized_keys_path}")
        @ssh.exec!("chown #{@name}:#{@name} #{@authorized_keys_path}")
        c = @ssh.scp.download! @authorized_keys_path
      end  
    end

  end
end
