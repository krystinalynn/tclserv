$::maintype sendUid $::sock($::cs(netname)) $cs(nick) $cs(ident) $cs(host) $cs(host) 77 "Channels Server"
bind $::sock($::cs(netname)) msg 77 "register" regchan
bind $::sock($::cs(netname)) msg 77 "adduser" adduserchan
bind $::sock($::cs(netname)) msg 77 "users" lsuchan
bind $::sock($::cs(netname)) msg 77 "lsu" lsuchan
bind $::sock($::cs(netname)) msg 77 "convertop" convertop
#bind $::sock($::cs(netname)) msg 77 "deluser" deluserchan
bind $::sock($::cs(netname)) msg 77 "up" upchan
bind $::sock($::cs(netname)) pub "-" "@up" upchanfant
bind $::sock($::cs(netname)) pub "-" "@rand" randfant
bind $::sock($::cs(netname)) pub "-" "@request" requestbot
bind $::sock($::cs(netname)) msg 77 "down" downchan
bind $::sock($::cs(netname)) msg 77 "hello" regnick
bind $::sock($::cs(netname)) msg 77 "chpass" chpassnick
bind $::sock($::cs(netname)) msg 77 "login" idnick
bind $::sock($::cs(netname)) msg 77 "help" chanhelp
bind $::sock($::cs(netname)) msg 77 "topic" chantopic
bind $::sock($::cs(netname)) msg 77 "cookie" authin
bind $::sock($::cs(netname)) msg 77 "cauth" cookieauthin
bind $::sock($::cs(netname)) mode "-" "+" checkop
bind $::sock($::cs(netname)) mode "-" "-" checkdeop
bind $::sock($::cs(netname)) topic "-" "-" checktopic
bind $::sock($::cs(netname)) create "-" "-" checkcreate

proc checktopic {chan topic} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {[channel get $chan topiclock]} {$::maintype topic $::sock($::cs(netname)) 77 "$chan" "[nda get "regchan/$ndacname/topic"]"}
}

proc chantopic {from msg} {
	set cname [lindex $msg 0 0]
	set topic [join [lrange [lindex $msg 0] 1 end] " "]
	if {""==[tnda get "login/$::netname($::sock($::cs(netname)))/$from"]} {$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life.";return}
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {150>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock($::cs(netname)))/$from"]]"] && ![matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] lmno|lmno $cname]} {
		$::maintype privmsg $::sock($::cs(netname)) 77 $cname "You must be at least halfop to change the stored channel topic."
		return
	}
	nda set "regchan/$ndacname/topic" "$topic"
	$::maintype topic $::sock($::cs(netname)) 77 "$cname" "$topic"
	$::maintype privmsg $::sock($::cs(netname)) 77 "$cname" "[tnda get "nick/$::netname($::sock($::cs(netname)))/$from"] ([tnda get "login/$::netname($::sock($::cs(netname)))/$from"]) changed topic."
}

proc authin {from msg} {
	set uname [lindex $msg 0 0]
	if {[string first "/" $uname] != -1} {return}
	$::maintype notice $::sock($::cs(netname)) 77 $from "CHALLENGE [set cookie [b64e [rand 1000000000 9999999999]]] SHA1"
	tnda set "cookieauth/$from/cookie" $cookie
	tnda set "cookieauth/$from/name" "$uname"
}

proc cookieauthin {from msg} {
	set uname [lindex $msg 0 0]
	set response [lindex $msg 0 1]
	if {[string first "/" $uname] != -1} {return}
	if {$response == ""} {return}
	set checkresp "[tnda get "cookieauth/$from/name"]:[nda get "usernames/[string tolower $uname]/password"]:[tnda get "cookieauth/$from/cookie"]"
	set isresp [pwhash "$checkresp"]
	puts stdout "$response $isresp $checkresp"
	if {$response == $isresp} {
		$::maintype notice $::sock($::cs(netname)) 77 $from "You have successfully logged in as $uname."
		$::maintype setacct $::sock($::cs(netname)) $from $uname
		callbind $::sock($::cs(netname)) evnt "-" "login" $from $uname
	} {
		$::maintype notice $::sock($::cs(netname)) 77 $from "You used the wrong password; try again."
	}
}

proc randfant {cname msg} {
	set from [lindex $msg 0 0]
	set froni [tnda get "nick/$::netname($::sock($::cs(netname)))/$from"]
	if {![string is integer [lindex $msg 1 0]] ||![string is integer [lindex $msg 1 1]]} {return}
	if {(""==[lindex $msg 1 0]) || (""==[lindex $msg 1 1])} {return}
	if {[lindex $msg 1 0] == [lindex $msg 1 1]} {$::maintype privmsg $::sock($::cs(netname)) 77 $cname "\002$froni:\002 Your request would have caused a divide by zero and was not processed.";return}
	$::maintype privmsg $::sock($::cs(netname)) 77 $cname "\002$froni:\002 Your die rolled [rand [lindex $msg 1 0] [lindex $msg 1 1]]"
}

proc lsuchan {from msg} {
	set cname [lindex $msg 0 0]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {[string length [nda get "regchan/$ndacname"]] == 0} {
		$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life."
		$::maintype notice $::sock($::cs(netname)) 77 $from "Channel does not exist."
		return
	}
	set xses [nda get "regchan/$ndacname/levels"]
	$::maintype notice $::sock($::cs(netname)) 77 $from "Access | Flags  | Username"
	$::maintype notice $::sock($::cs(netname)) 77 $from "-------+------------------"
	foreach {nick lev} $xses {
		if {$lev == 0} {continue}
		# Case above? User not actually on access list
		set nl [format "%3d" $lev]
		set repeats [string repeat " " [expr {6-[string length [nda get "eggcompat/attrs/$ndacname/$nick"]]}]]
	$::maintype notice $::sock($::cs(netname)) 77 $from "  $nl  | $repeats[string range [nda get "eggcompat/attrs/$ndacname/$nick"] 0 5] | $nick"
	}
	$::maintype notice $::sock($::cs(netname)) 77 $from "-------+------------------"
	$::maintype notice $::sock($::cs(netname)) 77 $from "       | End of access list"
}

proc upchanfant {cname msg} {
	set from [lindex $msg 0 0]
	if {""==[tnda get "login/$::netname($::sock($::cs(netname)))/$from"]} {$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life.";return}
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {(1>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock($::cs(netname)))/$from"]]"]) && ![matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] aolvmn|olvmn $cname]} {
		$::maintype privmsg $::sock($::cs(netname)) 77 $cname "You fail at life."
		$::maintype privmsg $::sock($::cs(netname)) 77 $cname "Channel not registered to you."
		return
	}
	set lev [nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock($::cs(netname)))/$from"]]"]
	set sm "+"
	set st ""
	if {""!=[nda get "eggcompat/attrs/$ndacname/[tnda get "login/$::netname($::sock($::cs(netname)))/$from"]"]} {
		if {[matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] |v $cname]} {set sm v}
		if {[matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] |l $cname]} {set sm [tnda get "pfx/halfop"]}
		if {[matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] |o $cname]} {set sm o}
		if {[matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] |m $cname]} {set sm [tnda get "pfx/protect"]}
		if {[matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] |n $cname]} {set sm [tnda get "pfx/owner"]}
	} {
		if {$lev >= 1} {set sm "v"; append st "v"}
		if {$lev >= 150} {set sm "h"; append st "l"}
		if {$lev >= 200} {set sm "o"; append st "o"}
		if {$lev >= 300} {append st "m"}
		if {$lev >= 500} {append st "n"}
		chattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] +$st $cname
	}
	$::maintype putmode $::sock($::cs(netname)) 77 $cname +$sm $from [tnda get "channels/$::netname($::sock($::cs(netname)))/$ndacname/ts"]
}

proc convertop {from msg} {
	if {""==[tnda get "login/$::netname($::sock($::cs(netname)))/$from"]} {$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {500>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock($::cs(netname)))/$from"]]"]} {
		$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life."
		$::maintype notice $::sock($::cs(netname)) 77 $from "You must be the founder to request an oplevel-to-flags conversion."
		return
	}
	foreach {login lev} [nda get "regchan/$ndacname/levels"] {
		set st ""
		if {$lev >= 1} {append st "v"}
		if {$lev >= 150} {append st "l"}
		if {$lev >= 200} {append st "o"}
		if {$lev >= 300} {append st "m"}
		if {$lev >= 500} {append st "n"}
		chattr $login +$st $cname
	}
	$::maintype notice $::sock($::cs(netname)) 77 $from "Converted all access levels to flags."
	lsuchan $from $msg
}

proc requestbot {cname msg} {
	set from [lindex $msg 0 0]
	set bot [lindex $msg 1 0]
	if {""==[tnda get "login/$::netname($::sock($::cs(netname)))/$from"]} {$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life.";return}
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {150>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock($::cs(netname)))/$from"]]"] && ![matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] lmno|lmno $cname]} {
		$::maintype privmsg $::sock($::cs(netname)) 77 $cname "You fail at life."
		$::maintype privmsg $::sock($::cs(netname)) 77 $cname "You must be at least halfop to request $bot."
		return
	}
	callbind $::sock($::cs(netname)) request [string tolower $bot] "-" $cname
}

foreach {chan _} [nda get "regchan"] {
	$::maintype putjoin $::sock($::cs(netname)) 77 [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/ts"]
	tnda set "channels/$chan/ts" [nda get "regchan/$chan/$::netname($::sock($::cs(netname)))/ts"]
	$::maintype putmode $::sock($::cs(netname)) 77 [::base64::decode [string map {[ /} $chan]] "+o" $::cs(nick) [nda get "regchan/$chan/ts"]
	$::maintype putmode $::sock($::cs(netname)) 77 [::base64::decode [string map {[ /} $chan]] "+nt" "" [nda get "regchan/$chan/ts"]
	if {[channel get [::base64::decode [string map {[ /} $chan]] topiclock]} {$::maintype topic $::sock($::cs(netname)) 77 [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/topic"]}
}

proc checkop {mc ftp} {
	set f [lindex $ftp 0 0]
	set t [lindex $ftp 0 1]
	set p [lindex $ftp 0 2]
	if {"o"!=$mc} {return}
	set chan [string map {/ [} [::base64::encode [string tolower $t]]]
	tnda set "channels/$chan/modes/$p" "[tnda get "channels/$chan/modes/$::netname($::sock($::cs(netname)))/$::netname($::sock($::cs(netname)))/$p"]o"
}

proc checkcreate {mc ftp} {
	set chan [string map {/ [} [::base64::encode [string tolower $mc]]]
	tnda set "channels/$chan/modes/$::netname($::sock($::cs(netname)))/$ftp" "o"
	puts stdout "channels/$chan/modes/$ftp"
}

proc checkdeop {mc ftp} {
	set f [lindex $ftp 0 0]
	set t [lindex $ftp 0 1]
	set p [lindex $ftp 0 2]
	if {"o"!=$mc} {return}
	set chan [string map {/ [} [::base64::encode [string tolower $t]]]
	tnda set "channels/$chan/modes/$p" [string map {o ""} [tnda get "channels/$chan/modes/$::netname($::sock($::cs(netname)))/$::netname($::sock($::cs(netname)))/$p"]]
}

proc chanhelp {from msg} {
	set fp [open ./chanserv.help r]
	set data [split [read $fp] "\r\n"]
	close $fp
	foreach {line} $data {
		$::maintype notice $::sock($::cs(netname)) 77 $from "$line"
	}
}

proc regchan {from msg} {
	putcmdlog "$from $msg regchan"
	if {""==[tnda get "login/$::netname($::sock($::cs(netname)))/$from"]} {$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {[string length [nda get "regchan/$ndacname"]] != 0} {
		$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life."
		$::maintype notice $::sock($::cs(netname)) 77 $from "Channel already exists."
		return
	}
	if {-1==[string first "o" [ts6 getpfx $::netname($::sock($::cs(netname))) $cname [ts6 uid2nick $::cs(netname) $from]]]} {
		$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life."
		$::maintype notice $::sock($::cs(netname)) 77 $from "You are not an operator. [ts6 getpfx $::netname($::sock($::cs(netname))) $cname [ts6 uid2nick $::cs(netname) $from]]"
		return
	}
	$::maintype notice $::sock($::cs(netname)) 77 $from "Guess what? :)"
	nda set "regchan/$ndacname/levels/[tnda get "login/$::netname($::sock($::cs(netname)))/$from"]" 500
	nda set "regchan/$ndacname/ts" [tnda get "channels/$::netname($::sock($::cs(netname)))/$ndacname/ts"]
	$::maintype putjoin $::sock($::cs(netname)) 77 $cname [tnda get "channels/$::netname($::sock($::cs(netname)))/$ndacname/ts"]
	chattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] +mno $cname
	callbind $::sock($::cs(netname)) "reg" "-" "-" $cname [tnda get "channels/$::netname($::sock($::cs(netname)))/$ndacname/ts"]
}

proc adduserchan {from msg} {
	if {""==[tnda get "login/$::netname($::sock($::cs(netname)))/$from"]} {$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set adduser [lindex $msg 0 1]
	set addlevel [lindex $msg 0 2]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {![string is integer $addlevel]} {return}
	if {$addlevel > [nda get "regchan/$ndacname/levels/[tnda get "login/$::netname($::sock($::cs(netname)))/$from"]"]} {$::maintype notice $::sock($::cs(netname)) 77 $from "You can't do that; you're not the channel's Dave";return}
	if {[nda get "regchan/$ndacname/levels/$adduser"] > [nda get "regchan/$ndacname/levels/[tnda get "login/$::netname($::sock($::cs(netname)))/$from"]"]} {$::maintype notice $::sock($::cs(netname)) 77 $from "You can't do that; the person you're changing the level of is more like Dave than you.";return}
	if {$adduser == [tnda get "login/$::netname($::sock($::cs(netname)))/$from"]} {$::maintype notice $::sock($::cs(netname)) 77 $from "You can't change your own level, even if you're downgrading. Sorreh :/$::netname($::sock($::cs(netname)))/";return}
	$::maintype notice $::sock($::cs(netname)) 77 $from "Guess what? :) User added."
	nda set "regchan/$ndacname/levels/[string tolower $adduser]" $addlevel
}

proc upchan {from msg} {
	puts stdout [nda get regchan]
	if {""==[tnda get "login/$::netname($::sock($::cs(netname)))/$from"]} {$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {1>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock($::cs(netname)))/$from"]]"] && ![matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] aolvmn|olvmn $cname]} {
		$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life."
		$::maintype notice $::sock($::cs(netname)) 77 $from "Channel not registered to you."
		return
	}
	set lev [nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock($::cs(netname)))/$from"]]"]
	set sm "+"
	set st ""
	if {""!=[nda get "eggcompat/attrs/$ndacname/[tnda get "login/$::netname($::sock($::cs(netname)))/$from"]"]} {
		if {[matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] |v $cname]} {set sm v}
		if {[matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] |l $cname]} {set sm [tnda get "pfx/halfop"]}
		if {[matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] |o $cname]} {set sm o}
		if {[matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] |m $cname]} {set sm [tnda get "pfx/protect"]}
		if {[matchattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] |n $cname]} {set sm [tnda get "pfx/owner"]}
	} {
		if {$lev >= 1} {set sm "v"; append st "v"}
		if {$lev >= 150} {set sm "h"; append st "l"}
		if {$lev >= 200} {set sm "o"; append st "o"}
		if {$lev >= 300} {append st "m"}
		if {$lev >= 500} {append st "n"}
		chattr [tnda get "login/$::netname($::sock($::cs(netname)))/$from"] +$st $cname
	}
	$::maintype putmode $::sock($::cs(netname)) 77 $cname +$sm $from [tnda get "channels/$::netname($::sock($::cs(netname)))/$ndacname/ts"]
}

proc regnick {from msg} {
	set uname [lindex $msg 0 0]
	if {[string first "/" $uname] != -1} {return}
	set pw [lindex $msg 0 1]
	if {""!=[nda get "usernames/[string tolower $uname]"]} {
		$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life."
		$::maintype notice $::sock($::cs(netname)) 77 $from "Account already exists; try LOGIN"
		return
	}
	nda set "usernames/[string tolower $uname]/password" [pwhash $pw]
	$::maintype setacct $::sock($::cs(netname)) $from $uname
	callbind $::sock($::cs(netname)) evnt "-" "login" $from $uname
}

proc chpassnick {from msg} {
	set uname [lindex $msg 0 0]
	if {[string first "/" $uname] != -1} {return}
	set pw [lindex $msg 0 1]
	set newpw [lindex $msg 0 2]
	set checkpw [split [nda get "usernames/[string tolower $uname]/password"] "/"]
	set ispw [pwhash $pw]

	if {$ispw != [nda get "usernames/[string tolower $uname]/password"]} {
		$::maintype notice $::sock($::cs(netname)) 77 $from "You fail at life."
		$::maintype notice $::sock($::cs(netname)) 77 $from "Wrong pass."
		return
	}
	nda set "usernames/[string tolower $uname]/password" [pwhash $newpw]
	$::maintype notice $::sock($::cs(netname)) 77 $from "Password changed."
}

proc idnick {from msg} {
	set uname [lindex $msg 0 0]
	if {[string first "/" $uname] != -1} {return}
	set pw [lindex $msg 0 1]
	set checkpw [split [nda get "usernames/[string tolower $uname]/password"] "/"]
	set ispw [pwhash $pw]
	if {$ispw == [nda get "usernames/[string tolower $uname]/password"]} {
		$::maintype notice $::sock($::cs(netname)) 77 $from "You have successfully logged in as $uname."
		$::maintype setacct $::sock($::cs(netname)) $from $uname
		callbind $::sock($::cs(netname)) evnt "-" "login" $from $uname
	} {
		$::maintype notice $::sock($::cs(netname)) 77 $from "You cannot log in as $uname. You have the wrong password."
	}
}
