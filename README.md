Sshgw
=====

Firts version, very bad (no controls at all) of sshgw utility.

What ?
------

sshgw is a "simple" way to manage ssh gateway.

Imagine :

                                                             /--------------- Mail server
                                                            /
You --------- Internet ---------- Firewall ----------- LocalNetwork --------- ssh gateway (ssh server on a machine)
                                                            \
                                                             \_______________ Web server

When your are on the local network, it is possible to connect to the web server or to the mail server by typing :

ssh youruser@webserver or youruser@mailserver

But what are the solutions when your are outside of the local network ?

* you could redirect differents ports from your firewall, eg : port 2201 to port 22 of web server and port 2202 to port 22 of mail server. But in this case, you have to tel your client that you don't use the standard ssh port. You can use your personal ssh config file for that.

* Other methods here

Or you can use an ssh gateway so you could access the web server from the outside like this :

ssh webserver@yourdomain.org or
ssh mailserver@yourdomain.org

This is what sshgw is trying to do. In fact, not realy because sshgw is just a tool to configure this ssh gateway.

For example (on your dev machine) :

me@dev:~$ sshgw -n me -t ssh-gateway-srv -f webserver -a deploy
sshgw version : 0.0.3
Jacques-Daniel PILLON <jdpillon@lesalternatives.org>
Create webserver user on ssh-gateway-srv,
then add me's public key to webserver@ssh-gateway-srv:/home/webserver/.ssh/authorized_keys with the command option :
command='ssh -t deploy@webserver' ssh-rsa...
Are you ok with this ? (y/n)




Jacques-Daniel PILLON
