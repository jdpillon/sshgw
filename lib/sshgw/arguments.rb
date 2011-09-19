module Sshgw
  def self.parse(args)
    @options = {}

    optparse = OptionParser.new do |opts|
      opts.banner = "Usage : sshgw -a username -t sshgw-host -f hidden-srv -a username_on_hiddensrv"
      opts.on('-a', '--add', String, 'Add user') do |user|
        @options[:user] = user
      end
      opts.on('-h', '--help', 'Display this screen') do
        puts opts
        exit
      end
    end
    optparse.parse!(args)
    p @options.inspect
  end
end
