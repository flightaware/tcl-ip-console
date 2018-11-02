#
# console.tcl - Itcl class to generate a server socket on a specified port that
#  provides a console interface for the application that can be telnetted to.
#
# Usage:
#
#   package require fa_console
#
#   IpConsole console
#   console setup_server -port 8888
#
#   telnet localhost 8888
#

package require Itcl

catch {::itcl::delete class IpConsole}

::itcl::class IpConsole {
    public variable port 8888
    public variable connectedSockets ""

    protected variable serverSock
    protected variable clientSock {}
    protected variable isBlocked false

    constructor {args} {
		configure {*}$args
    }

    destructor {
        stop_server
    }

	#
	# log_message - log a message to stderr including the name of the object
	#   through which log_message is being invoked ($this)
	#
    method log_message {message} {
		puts stderr "$this: $message"
    }

	#
	# wall - send a message to all connected clients
	#
	method wall {message} {
	    foreach sock $connectedSockets {
		    if {[catch {puts $sock [list wall $message]} catchResult] == 1} {
			    log_message "got '$catchResult' writing to sock $sock"
				close_client_socket $sock
			}
		}
	}

    #
    # handle_connect_request - handle a request to connect to the console
    #  port from a remote client
    #
    method handle_connect_request {socket ip port} {
		log_message "connect from $socket $ip $port"
		if {$ip != "127.0.0.1"} {
			log_message "ip not localhost, ignored"
			close $socket
			return
		}
		fileevent $socket readable "$this handle_remote_request $socket"
		fconfigure $socket -blocking 0 -buffering line

		puts $socket [list connect "$::argv0 - connect from $ip $port - help for help"]

		# add the socket to the list of connected sockets if it's not there already
	    set whichSock [lsearch -exact $connectedSockets $socket]
		if {$whichSock < 0} {
			lappend connectedSockets $socket
		}
    }

	#
	# close_client_socket - close a socket on a client connection, removing
	#  it from the list of connected sockets (if it can be found there)
	#  and making sure the close doesn't cause a traceback no matter what
	#
	method close_client_socket {sock} {
	    # remove the socket from the list of connected sockets
	    set whichSock [lsearch -exact $sock $connectedSockets]
		if {$whichSock >= 0} {
		    set connectedSockets [lreplace $connectedSockets $whichSock $whichSock]
		}

		if {[catch {close $sock} catchResult] == 1} {
		    log_message "error closing $sock: $catchResult (ignored)"
		}
	}

    #
    # handle_remote_request - handle a request from a connected client
    #
    method handle_remote_request {sock} {
		if {[catch {eof $sock} isEof]} {
			# if we cannot check eof, then the remote closed
			return
		}
		if {$isEof} {
			log_message "EOF on $sock"
			close_client_socket $sock
			return
		}

		if {[gets $sock line] >= 0} {
			switch -- $line {
				"help" {
					puts $sock [list ok "quit, exit - disconnect, help - this help, !quit, !exit, !help - execute quit, exit or help on the server"]
					return
				}

				"quit" {
					puts $sock [list ok goodbye]
					close_client_socket $sock
					return
				}

				"exit" {
					puts $sock [list ok "goodbye, use !exit to exit the server"]
					close_client_socket $sock
					return
				}
				"continue" {
					set isBlocked false
				}

				"!quit" {
					# they want us to send a quit to the server
					set line "quit"
				}

				"!exit" {
					# they want us to send "exit" to the server
					set line "exit"
				}

				"!help" {
					set line "help"
				}

				"!continue" {
					set line "continue"
				}
			}

			if {[catch {uplevel #0 $line} result] == 1} {
				puts $sock [list error $result]
			} else {
				puts $sock [list ok $result]
			}
		}
    }

    #
    # setup_server - set up to accept connections on the server port
    #
    method setup_server {args} {
		eval configure $args

		stop_server

		if {[catch {socket -server [list $this handle_connect_request] $port} serverSocket] == 1} {
			log_message "Error opening server socket: $port: $serverSocket"
			return 0
		}
		return 1
    }

    #
    # stop_server - stop accepting connections on the server socket
    #
    method stop_server {} {
		if {[info exists serverSock]} {
			if {[catch {close $serverSock} result] == 1} {
				log_message "Error closing server socket '$serverSock': $result"
			}
			unset serverSock
		}
    }

    #
    # Send a message to a remote listening port.
    # Connects to the port as needed
    #
    method send_out {arg {blocking true} {host 127.0.0.1} {port 8989}} {
        if {$clientSock == {}} {
            if { [catch {socket $host $port} clientSock]} {
		# failure to open is ok
		# caller can retry if needed
		return 0
	    }
	    handle_connect_request $clientSock 127.0.0.1 0
	}
	wall $arg
	if {$blocking} {
	    set isBlocked true
	    while {$isBlocked} {
	        handle_remote_request $clientSock
	    }
        }
	return 1
    }
}

package provide fa_console 1.1
