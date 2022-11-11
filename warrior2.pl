#!/usr/bin/perl -w

### A simple MUD robot designed to run on the Isengard MUD based on Mordor code
### This code is adapted to the warrior class, and later on, to the crusader guild
###
### Usage: perl warrior.pl

# We will use a raw socket to connect to the IRC server.
use IO::Socket;

# The server to connect to and our details.
$server = "isengard.nazgul.com";
$port = "4040";
$character = "warrior";
$password = "qwerty";

# Robot AI variables
$max_hp = 0;		# Max HP of character
$half_hp = 0;		# HP at which character must heal
$fight_mode = 0;	# Do not start in fight mode; see heal mode
$circle_mode = 1;	# Start in circle mode when in fight_mode
$heal_mode = 1;		# Are we in heal mode? (must be out of fight_mode)
$mob_hit = 0;		# We need to determine if this hit killed mob or not

# DEBUG
$debug = 1;		# print debug information

# Connect to the MUD server.
$sock = IO::Socket::INET->new(PeerAddr => $server,
				PeerPort => $port,
				Proto => 'tcp');

# Log on to the server.
print $sock "$character\r\n";
print $sock "$password\r\n";

###
### SET MAX HP/MP OF CHARACTER
###

if ($debug) {
	print ">>> SETTING VARIABLES\n";
}

print $sock "score\r\n";

$vars = 0;	# Variable counter; need to process two variables
while ($vars != 2) {

	$input = <$sock>;
	chop $input;
	print "$input\n";

	if ($input =~ /(\d+) Hit Points/) {
		$max_hp = $1;
		$half_hp = int(0.5*$1);
		if ($debug) {
			print ">>> MAX HP=$max_hp (Heal HP=$half_hp)\n";
		}
		$vars++;
	}
	if ($input =~ /(\d+) Magic Points/) {
		print ">>> MAX MP=$1\n";	# No need to store max_mp
		$vars++;			# Completed
	}
}

###
### GET TARGET BLOCK
###

$nolook = 1;	# LOOK once at beginning for targets
if ($nolook) {
	print $sock "l\r\n";				# Look if mob already present
	$nolook = 0;					# Don't spam LOOK at every loop
}

if ($debug) {
	print ">>> GET TARGET BLOCK\n";
}

while (!$fight_mode) {

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
	if ($input =~ /You see/) {			# I see either mobs or loot
		if ($debug) {
			print ">>> LOOKING\n";
		}

		# CLINIC (GOOD mobs)
		if ($input =~ /student/) {
			if ($debug) {
				print ">>> FOUND STUDENT\n";
			}
			$fight_mode = 1;
			$mob = "student";
		}
	}

	if ($input =~ /just arrived/) {			# Either a mob or player arrived
		if ($input =~ /student/) {
			if ($debug) {
				print ">>> FOUND STUDENT\n";
			}
			$fight_mode = 1;
			$mob = "student";
		}
	}
}

###
### ATTACK TARGET: START OF BLOCK
###

while ($fight_mode) {

if ($debug) {
	print ">>> FIGHT MODE: $mob\n";
}

### SUB-BLOCK: CIRCLE

if ($debug) {
	print ">>> CIRCLE MODE\n";
}

while ($circle_mode) {

	# Make sure the circle is given!
	print $sock "ci $mob\r\n";
	if ($debug) {
		print ">>> ci $mob\n";
	}

	# Process next line and echo it
	$input = <$sock>;
	chop $input;
	if ($input =~ /Please wait/) {
		if ($debug) {
			print ">>> WAITING 1 SECOND\n";
		}
		sleep 1;		# sleep for 1 second
		#select(undef, undef, undef, 0.5);	# sleep() for fraction of a second
	}
	else {
		print "$input\n";
	}

	# End fight if:
	# (A) mob left before we circle it
	# (B) mob is sheep from "sheep skin" broken into two input lines!

	if ($input =~ /You don't see that here/) {
		if ($mob eq "sheep") {
			print $sock "get skin\r\n";		# Remove that offensive item!
		}
		$fight_mode = 0;
		$circle_mode = 0;
	}
	# Managed to aggro the mob
	if ($input =~ /You circle/) {
		$circle_mode = 0;
	}
	if ($input =~ /You failed to circle/) {
		# Do nothing; keep on circling until success!
		# Need to check health if taking a beating from mob
	}
}

### SUB-BLOCK: ATTACK

if ($debug) {
	print ">>> ATTACK MODE\n";
}

while (!$circle_mode) {

	# Make sure the attack is given!
	print $sock "k $mob\r\n";
	if ($debug) {
		print ">>> k $mob\n";
	}

	# Process next line and echo it
	$input = <$sock>;
	chop $input;
	if ($input =~ /Please wait/) {
		if ($debug) {
			print ">>> WAITING 1 SECOND\n";
		}
		sleep 1;		# sleep for 1 second
		#select(undef, undef, undef, 0.5);	# sleep() for fraction of a second
	}
	else {
		print "$input\n";
	}

	###
	### Circle mob after attack is executed (successful or not)
	###

	# Hit mob
	if ($input =~ /Your unarmed strike hits for (\d+) damage/) {
		$circle_mode = 1;
		$mob_hit = 1;
		print $sock "clap\r\n";		# clap hands
		if ($debug) {
			print ">>> HIT\n";
		}
	}
	if ($input =~ /CRITICAL HIT/) {
		$circle_mode = 1;
		$mob_hit = 1;
		print $sock "clap\r\n";		# clap hands
		if ($debug) {
			print ">>> CRITICAL HIT\n";
		}
	}

	# Missed mob
	if ($input =~ /You missed/) {
		$circle_mode = 1;
		if ($debug) {
			print ">>> MISS\n";
		}
	}

	# Fumbles
	if ($input =~ /You.*UMBLE/) {		# FUMBLED or STUMBLE
		$circle_mode = 1;
		if ($debug) {
			print ">>> FUMBLE\n";
		}
	}

	###
	### End fight if mob is dead, flee, or killed by another person
	###

###
### CANNOT BE HERE OTHERWISE IT WILL NEVER BE PROCESSED!
### AFTER FINAL "HIT" IT WILL GO TO "CIRCLE MODE" AND PROCESS
### THE "YOU KILLED" MESSAGE THERE.  PROBLEM IS THAT IT WILL SPAM
### "CI MOB" BEFORE IT SEES THE MESSAGE, POTENTIALLY ATTACKING
### ANOTHER MOB!
###
### idea:
### after hit or critical hit, clap hands
### wait for "You clap your hands" message to process the "You killed"

	if ($input =~ /You killed/) {
		if ($debug) {
			print ">>> $mob killed\n";
		}
		$circle_mode = 1;
		$fight_mode = 0;
	}
}

while ($mob_hit) {

	# Process next line and echo it
	$input = <$sock>;
	chop $input;
	print "$input\n";

	if ($input =~ /You killed/) {	# This message should appear before the next one
		if ($debug) {
			print ">>> $mob killed\n";
		}
		$circle_mode = 1;
		$fight_mode = 0;
	}	

	if ($input =~ /You clap your hands/) {		# Clapped our hands
		$mob_hit = 0;		# Exit this loop
	}	
}

###
### ATTACK TARGET: END OF BLOCK
###

}

###
### QUIT GAME
###

print $sock "quit\r\n";
