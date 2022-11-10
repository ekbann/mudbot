#!/usr/bin/perl -w
# irc.pl
# A simple MUD robot.
# Usage: perl ibot.pl

# We will use a raw socket to connect to the IRC server.
use IO::Socket;

# The server to connect to and our details.
$server = "isengard.nazgul.com";
$port = "4040";
$character = "stormwind";
$password = "qwerty";

# Robot AI variables.
$healthy = 0;	# assume NOT healthy to fight
$fight = 0;		# do NOT start in fight mode
$mob = "";		# no mob assigned
$hpv = 55;		# vig if less than 55 HP
$hpm = 45;		# mend or meditate if less than 45 HP
$mpt = 20;		# tick until full if less than 20 MP
$tick = 0;		# tick mode
$xp = 0;		# xp counter
$damage = 0;	# damage done counter
$miss = 0;		# missed hits
$hit = 0;		# hits done
$fumble = 0;	# fumbles
$xpmax = 1000;	# how much XP to gain in this session
$xpok = 0;		# did not reach $xpmax value

# Connect to the MUD server.
$sock = IO::Socket::INET->new(PeerAddr => $server,
				PeerPort => $port,
				Proto => 'tcp');

# Log on to the server.
print $sock "$character\r\n";
print $sock "$password\r\n";
print $sock "rem all\r\n";

# Loop until required XP is reached
while (!$xpok) {

	# Read lines from the server and display them.
	# The MUD's prompt (24 H 2 M): does not end with a \n so the $input
	# variable will not be assigned and processed until some server event
	# is sent and actually closes the $input=<$sock> command.

	# print "ENTER HEAL/TICK ROUTINE\n";
	while (!$fight) {

		# Echo server output
		$input = <$sock>;
		chop $input;
		print "$input\n";

		# Check health status
		if ($input =~ /(\d+) H (\d+) M/) {
			# print "HP=$1 / MP=$2\n";
			if ($1 < $hpm) {
				$healthy = 0;
				# print "NOT HEALTHY\n";
				if ($2 >= 4) {	
					# print "MEND-WOUNDS\n";
					print $sock "c mend\r\n";
				}
			}
			elsif ($1 < $hpv) {
				$healthy = 0;
				# print "NOT HEALTHY\n";
				if ($2 >= 2) {	
					# print "VIGOR\n";
					print $sock "c vig\r\n";
				}
			}
			elsif (($1 >= $hpv) && (!$healthy)) {
				$healthy = 1;
				# print "HEALTHY\n";
			}
			if ($2 < $mpt) {
				$tick = 1;
				# print "TICKING\n";
			}
			elsif (($2 >= $mpt) && ($tick)){
				$tick = 0;
				# print "TICKING OFF\n";
			}
		}

		# Add gained XP
		if ($input =~ /You gained (\d+) experience/) {
			print "XP GAIN: $1\n";
			$xp += $1;
			print "XP TOTAL: $xp\n";
			if ($xp > $xpmax) {
				$xpok = 1;
				$fight = 1;		# To get out of this loop and exit
			}
		}

		# Check loot
		if ($input =~ /was carrying:/) {
			if ($input =~ /gold coin/) {
				print $sock "get coin\r\n";
			}
			if ($input =~ /wool mask/) {
				print $sock "get wool\r\n";
			}
		}

		# Check for being attacked
		if ($input =~ /The (\w+) hit you for/) {
			print "ATTACKING: $1\n";
			$fight = 1;
			$mob = $1;
		}

		# Check for sheep
		if ($input =~ /sheep.*just arrived/) {
			# print "IN: SHEEP\n";
			if (!$tick && $healthy) {
				$fight = 1;
			}
			$mob = "sheep";
		}

		# Check for goat
		if ($input =~ /goat.*just arrived/) {
			# print "IN: GOAT\n";
			if (!$tick && $healthy) {
				$fight = 1;
			}
			$mob = "goat";
		}

		# Check for llama
		if ($input =~ /llama.*just arrived/) {
			# print "IN: LLAMA\n";
			if (!$tick && $healthy) {
				$fight = 1;
			}
			$mob = "llama";
		}
	}

	print $sock "k $mob\r\n";

	# print "ENTER FIGHT ROUTINE\n";
	# Fight routine
	while ($fight && !$xpok) {

		# Identify mob
		# print "FIGHT: $mob\n";

		# Initiate fight
#		if ($fight) {
			# print "K $mob\n";
#			print $sock "k $mob\r\n";
#		}

		# Process next line and echo it
		$input = <$sock>;
		chop $input;
		if ($input !~ /Please wait/) {
			print "$input\n";
		}

		# Check health status
		if ($input =~ /(\d+) H (\d+) M/) {
			# print "HP=$1 / MP=$2\n";
			if ($1 < $hpm) {
				$healthy = 0;
				# print "NOT HEALTHY\n";
				if ($2 >= 4) {	
					# print "MEND-WOUNDS\n";
					print $sock "c mend\r\n";
				}
			}
			elsif ($1 < $hpv) {
				$healthy = 0;
				# print "NOT HEALTHY\n";
				if ($2 >= 2) {	
					# print "VIGOR\n";
					print $sock "c vig\r\n";
				}
			}
			elsif (($1 >= $hpv) && (!$healthy)) {
				$healthy = 1;
				# print "HEALTHY\n";
			}
		}

		if ($input =~ /hit you for/) {
			print $sock "k $mob\r\n";
		}

		if ($input =~ /missed you/) {
			print $sock "k $mob\r\n";
		}

		# Hit mob
		if ($input =~ /Your unarmed strike hits for (\d+) damage/) {
			$hit++;
			$damage += $1;
			# print "TOTAL DMG: $damage\n";
		}

		# Missed mob
		if ($input =~ /You missed/) {
			$hit++;
			$miss++;
		}

		# Fumbles
		if ($input =~ /You FUMBLED/) {
			$hit++;
			$fumble++;
		}

		# End fight if mob is dead
		if ($input =~ /You killed the/) {
			$fight = 0;
		}
	}
}

# Summary
print "**************\n";
print "XP GAINED: $xp\n";
print "MISSED HITS: $miss\n";
print "FUMBLES: $fumble\n";
print "SWINGS ATTEMPTED: $hit\n";
print "% MISS: ",int(($miss+$fumble)/$hit*100),"%\n";
print $sock "quit\r\n";
