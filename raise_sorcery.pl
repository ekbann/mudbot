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
$character = "stormwind";
$password = "qwerty";

# Robot AI variables
$fight_mode = 0;	# Do not start in fight mode
$tick_mode = 1;		# Are we in tick mode?
$fumble_mode = 0;
$casting_spell = 0;	# To avoid spamming BLISTER / FUMBLE
$no_mp = 0;		# flag to avoid casting with no MP available
$target_prof = 50;	### TARGET PROFICIENCY OF SPELL REALM

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

$max_hp = 39;		# Max HP of character
$max_mp = 36;		# HP at which character must heal

###
### MAJOR LOOP
###

while ($current_prof != $target_prof) {

###
### TICK BLOCK
###

if ($debug) {
	print ">>> ENTER TICK BLOCK\n";
}

print $sock "tap\r\n";		# Give us a prompt and start ticking

while ($tick_mode) {
	# Process next line and echo it
	$input = <$sock>;
	chop $input;
	if ($input !~ /Please wait/) {
		print "$input\n";
	}

	if ($input =~ /You tap your foot/) {	
		# Check magic point status
		if ($input =~ /(\d+) H (\d+) M/) {
			if ($debug) {
				print ">>> CURRENT: HP=$1 / MP=$2\n";
			}
			if (($2 < $max_mp) || ($1 < $max_hp)) {
				if ($debug) {
					print ">>> WAITING 20 SECOND\n";
				}
				sleep 20;		# sleep for 20 seconds
				print $sock "tap\r\n";	# Give us a prompt
			}
			else {
				if ($debug) {
					print ">>> FULL\n";
				}
				$tick_mode = 0;
				$no_mp = 0;
			}
		}
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
			$fumble_mode = 1;
			$mob = "student";
		}
	}

	if ($input =~ /just arrived/) {			# Either a mob or player arrived
		if ($input =~ /student/) {
			if ($debug) {
				print ">>> FOUND STUDENT\n";
			}
			$fight_mode = 1;	# Start fight
			$fumble_mode = 1;	# Start by casting FUMBLE
			$mob = "student";
		}
	}
}

###
### ATTACK TARGET: START OF BLOCK
###
### a) Cast FUMBLE spell until enough mana left to kill mob
### b) Kill mob by casting BLISTER spell (two if needed)
###

if ($debug) {
	print ">>> FIGHT MODE: $mob\n";
}

### SUB-BLOCK: FUMBLE

if ($debug) {
	print ">>> CASTING FUMBLE\n";
}

while ($fumble_mode) {

	# Make sure fumble is cast
	if ((!$casting_spell) && (!$no_mp)) {
		print $sock "c fum $mob\r\n";
		$casting_spell = 1;	# Do not cast again until we see the effect
		if ($debug) {
			print ">>> c fum $mob\n";
		}
	}

	# Process next line and echo it
	$input = <$sock>;
	chop $input;
	if ($input !~ /Please wait/) {
		print "$input\n";
	}

	# Check magic point status
	if ($input =~ /(\d+) H (\d+) M/) {
		if ($2 < 11) {
			if ($debug) {
				print ">>> NO MORE MP ($2) FOR FUMBLE\n";
			}
			$fumble_mode = 0;
			$no_mp = 1;
		}
	}

	if ($input =~ /Please wait/) {	# The only waiting is due to casting...
		if ($debug) {
			print ">>> WAITING 2 SECOND\n";
		}
		sleep 2;		# sleep for 2 second
		if (!$no_mp) {
			print $sock "c fum $mob\r\n";	# No need to set flag because the cast above already did
							# which generated this 'Please wait' text.
		}
	}

	# End fight if mob left before we cast on it
	if ($input =~ /That's not here/) {
		$fight_mode = 0;
		$fumble_mode = 0;
	}

	# Managed to aggro the mob
	if ($input =~ /Fumble spell cast/) {
		$casting_spell = 0;	# Now we can cast again!
		if ($debug) {
			print ">>> CAST AGAIN\n";
		}

	}

#	if ($input =~ /You failed to circle/) {		# Keep this in case failed cast occurs.
#		# Do nothing; keep on circling until success!
#		# Need to check health if taking a beating from mob
#	}

}

$casting_spell = 0;	# Casting is now available

while ($fight_mode) {

	### SUB-BLOCK: BLISTER

	if ($debug) {
		print ">>> CASTING BLISTER\n";
	}

	# Make sure the attack is given!

	if (!$casting_spell) {
		print $sock "c blis $mob\r\n";
		$casting_spell = 1;	# Do not cast again until we see the effect
		if ($debug) {
			print ">>> c blis $mob\n";
		}
	}

	while (!$tick_mode) {	# If mob is dead, then we have to tick

		# Process next line and echo it
		$input = <$sock>;
		chop $input;
		if ($input =~ /Please wait/) {	# The only waiting is due to casting...
			if ($debug) {
				print ">>> WAITING 2 SECOND\n";
			}
			sleep 2;			# sleep for 2 second
			print $sock "c blis $mob\r\n";	# No need to set flag because the cast above already did
							# which generated this 'Please wait' text.
		}
		else {
			print "$input\n";
		}

		if ($input =~ /You cast a blister spell/) {
			$casting_spell = 0;	# Now we can cast again!
			if ($debug) {
				print ">>> CAST AGAIN\n";
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

		if ($input =~ /You gained/) {
			if ($debug) {
				print ">>> $mob killed\n";
			}
			$casting_spell = 0;
			$fumble_mode = 0;
			$fight_mode = 0;
			$tick_mode = 1;
		}
	}

###
### ATTACK TARGET: END OF BLOCK
###

}

###
### CHECK REALM PROGRESS
###

print $sock "inf\r\n";

while ($tick_mode) {
	# Process next line and echo it
	$input = <$sock>;
	chop $input;

	# Check magic point status
	if ($input =~ /Sorcery:\s+(\d+)/) {
		$current_prof = $1;
		$tick_mode = 0;		# Exit loop
		if ($debug) {
			print ">>> CURRENT: Sorcery = $1%\n";
		}
	}
}

$tick_mode = 1;		# Now do real ticking

###
### MAJOR LOOP END
###

}

###
### QUIT GAME
###

print $sock "quit\r\n";
