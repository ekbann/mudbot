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
$healthy = 0;		# assume NOT healthy to fight
$fight = 0;		# do NOT start in fight mode
$mob = "";		# no mob assigned
$hpv = 55;		# vig if less than 55 HP (default 80% of 69HP)
$hpm = 45;		# mend or meditate if less than 45 HP (default 65% of 69HP)
$mpt = 20;		# tick until full if less than 20 MP (default 50% of 40MP)
$tick = 1;		# start in tick mode
$vars = 0;		# need to set hpm, hpv, and mpt to character's current level stats
$xp = 0;		# xp counter
$damage = 0;		# damage done counter
$miss = 0;		# missed hits
$hit = 0;		# hits done
$fumble = 0;		# fumbles
$xpmax = 2000;		# how much XP to gain in this session

# Connect to the MUD server.
$sock = IO::Socket::INET->new(PeerAddr => $server,
				PeerPort => $port,
				Proto => 'tcp');

# Log on to the server.
print $sock "$character\r\n";
print $sock "$password\r\n";

###
### SET HPV, HPM, & MPT
###

print ">>> SETTING VARIABLES\n";
print $sock "score\r\n";

while ($vars != 2) {

	$input = <$sock>;
	chop $input;
	print "$input\n";

	if ($input =~ /(\d+) Hit Points/) {
		print "MAX HP=$1\n";
		$hpv = int(0.8*$1);
		$hpm = int(0.65*$1);
		print "HPV=$hpv / HPM=$hpm\n";
		$vars++;
	}
	if ($input =~ /(\d+) Magic Points/) {
		print "MAX MP=$1\n";
		$mpt = int(0.5*$1);
		print "MPT=$mpt\n";
		$vars++;		# Completed
	}
}

# Read lines from the server and display them.
# The MUD's prompt (24 H 2 M): does not end with a \n so the $input
# variable will not be assigned and processed until some server event
# is sent and actually closes the $input=<$sock> command.

###
### HEAL/TICK BLOCK
###

print ">>> ENTER HEAL/TICK BLOCK\n";
print $sock "rem all\r\n";

while ($tick || !$healthy) {

	# Process next line and echo it
	$input = <$sock>;
	chop $input;
	if ($input !~ /Please wait/) {
		print "$input\n";
	}

	# Check health status
	if ($input =~ /(\d+) H (\d+) M/) {
		# print "HP=$1 / MP=$2\n";
		if ($1 < $hpv) {
			$healthy = 0;					# Need at least a vigor
			# print "NOT HEALTHY\n";
			if ($1 < $hpm) {
				if ($2 >= 4) {	
					# print "MEND-WOUNDS\n";
					print $sock "c mend\r\n";
				}
			}
			elsif ($2 >= 2) {	
				# print "VIGOR\n";
				print $sock "c vig\r\n";
			}
		}
		else {
			$healthy = 1;					# No vigor needed
		}
		if ($2 < $mpt) {
			$tick = 1;						# Need ticking for MP
			# print "TICKING\n";
		}
		else {
			$tick = 0;						# Have enough MP
			# print "TICKING OFF\n";
		}
	}
}


###
### INFINITE LOOP UNTIL REQUIRED XP GAINED
###

while ($xp < $xpmax) {

###
### GET TARGET BLOCK
###

$nolook = 1;	# LOOK once at beginning for targets
if ($nolook) {
	print $sock "l\r\n";				# Look if mob already present
	$nolook = 0;						# Don't spam LOOK at every loop
}

 print ">>> GET TARGET BLOCK\n";
while (!$fight) {

	# Process next line and echo it
	$input = <$sock>;
	chop $input;
	if ($input !~ /Please wait/) {
		if ($input !~ /You don't see that here/) {
			print "$input\n";
		}
	}

	# EXIT if server timed out; avoids a nasty script crash
	if ($input =~ /Timed out/) {
		exit;
	}

	# Check for present mobs
	if ($input =~ /You see/) {				# I see either mobs or loot
		# print "LOOKING\n";

		# ZOO (mostly EVIL)

		if ($input =~ /llama/) {
			# print "FOUND LLAMA\n";
			$fight = 1;
			$mob = "llama";
		}
		if ($input =~ /sheep/) {
			if ($input !~ /sheep skin/) {	# Make sure it's not a false mob
				# print "FOUND SHEEP\n";
				$fight = 1;
				$mob = "sheep";
			}
		}
		if ($input =~ /goat/) {
			# print "FOUND GOAT\n";
			$fight = 1;
			$mob = "goat";
		}
		
		# VILLAGE (GOOD mobs)
		
		if ($input =~ /ghost/) {
			# print "FOUND GHOST\n";
			$fight = 1;
			$mob = "ghost";
		}
		
		# BAR (mostly EVIL)
		
		if ($input =~ /bartender/) {
			# print "FOUND BARTENDER\n";
			$fight = 1;
			$mob = "bartender";
		}
		if ($input =~ /aristocrat/) {
			# print "FOUND ARISTOCRAT\n";
			$fight = 1;
			$mob = "aristocrat";
		}
		if ($input =~ /merchant/) {
			# print "FOUND MERCHANT\n";
			$fight = 1;
			$mob = "merchant";
		}
		if ($input =~ /waitress/) {
			# print "FOUND WAITRESS\n";
			$fight = 1;
			$mob = "waitress";
		}
		if ($input =~ /nobleman/) {
			# print "FOUND NOBLEMAN\n";
			$fight = 1;
			$mob = "nobleman";
		}
		if ($input =~ /drunk/) {
			# print "FOUND DRUNK\n";
			$fight = 1;
			$mob = "drunk";
		}
		if ($input =~ /laborer/) {
			# print "FOUND LABORER\n";
			$fight = 1;
			$mob = "laborer";
		}
		if ($input =~ /tourist/) {
			# print "FOUND TOURIST\n";
			$fight = 1;
			$mob = "tourist";
		}
		
		# POND (mostly EVIL)
		
		if ($input =~ /kid/) {
			# print "FOUND UGLY KID\n";
			$fight = 1;
			$mob = "kid";
		}
		if ($input =~ /hippie/) {
			# print "FOUND HIPPIE\n";
			$fight = 1;
			$mob = "hippie";
		}		
	}
	
	if ($input =~ /just arrived/) {			# Either a mob or player arrived
		if ($input =~ /llama/) {
			$fight = 1;
			$mob = "llama";
		}
		if ($input =~ /sheep/) {
			$fight = 1;
			$mob = "sheep";
		}
		if ($input =~ /goat/) {
			$fight = 1;
			$mob = "goat";
		}
		if ($input =~ /ghost/) {
			$fight = 1;
			$mob = "ghost";
		}
		if ($input =~ /bartender/) {
			$fight = 1;
			$mob = "bartender";
		}
		if ($input =~ /aristocrat/) {
			$fight = 1;
			$mob = "aristocrat";
		}
		if ($input =~ /merchant/) {
			$fight = 1;
			$mob = "merchant";
		}
		if ($input =~ /waitress/) {
			$fight = 1;
			$mob = "waitress";
		}
		if ($input =~ /nobleman/) {
			$fight = 1;
			$mob = "nobelman";
		}
		if ($input =~ /drunk/) {
			$fight = 1;
			$mob = "drunk";
		}
		if ($input =~ /laborer/) {
			$fight = 1;
			$mob = "laborer";
		}
		if ($input =~ /tourist/) {
			$fight = 1;
			$mob = "tourist";
		}
		if ($input =~ /kid/) {
			$fight = 1;
			$mob = "kid";
		}
		if ($input =~ /hippie/) {
			$fight = 1;
			$mob = "hippie";
		}
		# Avoid time outs
		print $sock "twid\r\n";
	}
}

###
### ATTACK TARGET BLOCK
###

 print ">>> ATTACK TARGET BLOCK: $mob\n";

# Use boolean to check when to leave this block because mob might be dead or not there before 
# the start of the attack

$nextblock = 0;

do {
	print $sock "k $mob\r\n";
	# Make sure the first hit is given!
	$input = <$sock>;
	chop $input;
	if ($input !~ /Please wait/) {
		if ($input !~ /You don't see that here/) {
			print "$input\n";
		}
	}
	# End fight if mob left before we hit it or is "sheep skin" broken into two lines!
	if ($input =~ /You don't see that here/) {
		if ($mob eq "sheep") {
			print $sock "get skin\r\n";		# Remove that offensive item!
		}
		$fight = 0;
		$nextblock = 1;
	}
	# Managed to attack mob
	if ($input =~ /You attack/) {
		$nextblock = 1;
	}
} until $nextblock;

while ($fight) {

	# Process next line and echo it
	$input = <$sock>;
	chop $input;
	if ($input !~ /Please wait/) {
		print "$input\n";
	}

	# Check health status
	if ($input =~ /(\d+) H (\d+) M/) {
		# print "HP=$1 / MP=$2\n";
		if ($1 < $hpv) {					# Need at least a vigor
			if ($1 < $hpm) {
				if ($2 >= 4) {	
					# print "MEND-WOUNDS\n";
					print $sock "c mend\r\n";
				}
			}
			elsif ($2 >= 2) {	
				# print "VIGOR\n";
				print $sock "c vig\r\n";
			}
		}
	}

	# Actual melee messages
	if ($input =~ /hit you for/) {
		print $sock "k $mob\r\n";
	}

	if ($input =~ /missed you/) {
		print $sock "k $mob\r\n";
	}

	if ($input =~ /casts.*spell on you for/) {
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
	if ($input =~ /You killed/) {
		$fight = 0;
	}

	### IF SOMEONE ATTACKS MY MOB, MOB WILL NO LONGER HIT ME, AND SO I WON'T HIT THE MOB EITHER
	### PAUSE ENDS IF: 1) THE PERSON LEAVES ROOM, OR 2) MOB IS KILLED AND I GAIN EXPERIENCE
	### IF PLAYER LEAVE, MOB WILL ATTACK ME AGAIN AND FIGHT WILL CONTINUE

	# End fight if mob already dead (someone killed it)
	if ($input =~ /You gained (\d+) experience/) {
		print "XP GAIN: $1\n";
		$xp += $1;
		print "XP TOTAL: $xp\n";
		print $sock "clap\r\n";		# Give a prompt to process health and go to TARGET MODE
		$fight = 0;
	}
}

###
### LOOT/HEAL/TICK BLOCK
###

$meditate = 1;			# Assume that player can meditate
$tick = 1;				# Assume need to tick
$healthy = 0;			# Assume need to heal

 print ">>> LOOT/HEAL/TICK BLOCK\n";
while ($tick || !$healthy) {

	# Process next line and echo it
	$input = <$sock>;
	chop $input;
	if ($input !~ /Please wait/) {
		if ($input !~ /You don't see that here/) {
			print "$input\n";
		}
	}

	# Add gained XP
	if ($input =~ /You gained (\d+) experience/) {
		print "XP GAIN: $1\n";
		$xp += $1;
		print "XP TOTAL: $xp\n";
		print $sock "clap\r\n";		# Give a prompt to process health and go to TARGET MODE
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

	# Disable meditate if not monk or needs to wait
	if ($input =~ /Only monks may meditate/) {
		$meditate = 0;
	}
	
	# Check health status
	if ($input =~ /(\d+) H (\d+) M/) {
		# print "HP=$1 / MP=$2\n";
		if ($1 < $hpv) {
			$healthy = 0;					# Need at least a vigor
			# print "NOT HEALTHY\n";
			if ($1 < $hpm) {
				if ($meditate) {
					# print "MEDITATE\n";
					print $sock "med\r\n";
				}
				elsif ($2 >= 4) {
					# print "MEND-WOUNDS\n";
					print $sock "c mend\r\n";
				}
				elsif ($2 >= 2) {			# Low on MP and need MEND... TROUBLE!
					# print "VIGOR\n";
					print $sock "c vig\r\n";
				}
				else {
					# print "HAZY\n";		# No MP and need MEND... GET OUT OF THERE!
					print $sock "dri dark\r\n";	# Use dark flask for debugging...
				}
			}
			elsif ($2 >= 2) {	
				# print "VIGOR\n";
				print $sock "c vig\r\n";
			}
		}
		else {
			$healthy = 1;					# No vigor needed
		}
		if ($2 < $mpt) {
			$tick = 1;						# Need ticking for MP
			# print "TICKING\n";
		}
		else {
			$tick = 0;						# Have enough MP
			# print "TICKING OFF\n";
		}
	}
}

}	# INFINITE LOOP CLOSE BRACE

###
### Summary
###

print "\n\n";
print ">>> XP GAINED: $xp\n";
print ">>> MISSED HITS: $miss\n";
print ">>> FUMBLES: $fumble\n";
print ">>> SWINGS ATTEMPTED: $hit\n";
print ">>> TOTAL DAMAGE DONE: $damage\n";
print ">>> % MISS: ",int(($miss+$fumble)/$hit*100),"%\n";
print ">>> AVERAGE DAMAGE PER HIT: ",int($damage/($hit-$fumble-$miss)),"\n";
print $sock "quit\r\n";

###
### TODO
###

# Check for being attacked
#	if ($input =~ /The (\w+) hit you for/) {
#		print "ATTACKING: $1\n";
#		$fight = 1;
#		$mob = $1;
#	}

### AVOID TIME OUTS : OK in GET TARGET BLOCK

### You don't see that here (false attack) AND inside ATTACK BLOCK (just wandered away) : OK

### Auto replies to TALKS

### HAZY followed by LOGOUT

### meditate to save on MP

### vig slave responding to: FOLLOW, JUMP, BLEED, LOGOUT

### Average damage : OK

### Attacked by aggro or previously attacking mob

### Go to fire pit to tick faster until 40

### I'm attacking and someone broadcasts You gainned x experience, ends fight and session!
