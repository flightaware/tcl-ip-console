#
# An example server that can demonstrate # the debug break and continue
#
# Before running this program start nc to receive the connect
# from the script.  Once connected try some TCL commands.
# We can read variables by creating objects that are returned
# by value. Remember puts will go to the output of the process with the IpConsole.
#
# dict create n $::example::n
#
# Then to continue type continue.  Here is an example session with this program.
#
# In one terminal,
# $ tclsh tests/example.tcl
# heartbeat
# heartbeat
# ...
#
# In a second terminal, but be fast you have ten seconds
# $ nc -l localhost 8989
# connect {tests/example.tcl - connect from 127.0.0.1 0 - help for help}
# wall {breakpoint at example.tcl:14}
# dict create n $::example::n
# ok {n 10}
# continue
# ok {}

source ip-console.tcl

namespace eval ::example {

set n 0
IpConsole ipConsole
# We are not starting the server.
# But you could start one if needed.
set forever false
}

proc ::example::heartbeat {} {
    incr ::example::n
    puts "hearbeat"
    if {($::example::n % 10) == 0} {
	    # every ten seconds stop
	    ipConsole send_out {breakpoint at example.tcl:14}
    }
    # keep running events
    after 1000 {::example::heartbeat}
}

after 1000 {::example::heartbeat}
vwait ::example::forever
