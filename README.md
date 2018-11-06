tcl-ip-console
---

The Tcl IP Console is an Itcl class that can generate a server socket on a specified TCP port of a machine and will accept connections on that port from localhost (127.0.0.1) only and execute whatever it receives from the socket in the Tcl interpreter and return whatever it receives from the Tcl interpreter back to the socket, along with the execution status, like "ok" or "error".

The Tcl program having the IP console added to it must principally use the Tcl event loop.  That is, the Tcl event loop needs to be running via "vwait" or that it is a Tk program or something for the IP console to work.

Usage
---

Add to your program something like...

```
package require fa_console

IpConsole console
console setup_server -port 8888
```

Accessing
---

Once your program is up and running, you can connect to the specified TCP port with nc, telnet or some other program, as in

```
nc localhost 8888
```

You will receive a greeting from the program, something that includes the program name ($::argv0), something like

```
$ nc  localhost 8888
connect {foo.tcl - connect from 127.0.0.1 44088 - help for help}
set forever true
ok true
```

Using
---

Whatever you type will be evaled at the top level of the running Tcl interpreter and the results will be sent back to the connection, along with whether the thing worked OK or whether there was an error.

For instance...

```
xset foo bar
error {invalid command name "xset"}
```

...or...

```
set foo bar
ok bar
```

You can poke around with stuff like "info globals", run procs from the command line and so forth.

One thing to note, though, "puts $foo" will not push the contents of the foo variable to your console session but will instead write it to whatever your program's standard output is pointed to.

For the above example if you want the contents of foo, use "return $foo" to get it sent to your console session.

Interesting Tidbits
---

Multiple concurrent sessions are support.

Since the IP console is an Itcl class, multiple IP consoles can be defined in a single program.  However, I don't know what that would be good for.


