require 'optparse'

module Sshgw
  def self.parse(args)
    @options = {}

    optparse = OptionParser.new do |opts|
      opts.banner = "Jacques-Daniel PILLON <jdpillon@lesalternatives.org>\nUsage : sshgw -n username -t sshgw-host -f hidden-srv -a username_on_hiddensrv\n"
      opts.on('-n', '--new USER', 'Add user') do |user|
        @options[:user] = user
      end
      opts.on('-t', '--to SSH-GATEWAY-HOST', 'ssh gateway') do |gwhost|
        @options[:gwhost] = gwhost
      end
      opts.on('-f', '--for INTERNAL-HOST', 'Internal host') do |internalhost|
        @options[:internalhost] = internalhost
      end
      opts.on('-a', '--as INTERNAL-USER', 'Internal user') do |internaluser|
        @options[:internaluser] = internaluser
      end





      opts.on('-h', '--help', 'Display this screen') do
        puts opts
        exit
      end
      if args.empty? or args.count < 4
        puts opts
        exit
      end
    end
    optparse.parse!(args)
    @options[:internaluser] = @options[:user] unless @options[:internaluser]
    return @options
  end
end
