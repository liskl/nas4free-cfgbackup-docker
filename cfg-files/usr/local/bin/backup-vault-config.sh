#!/bin/bash
### problem Statement
##   download nas4free router config and store in git

host=$SAN_HOST
user=$SAN_USER
passwd=$SAN_PASSWD

#Setup Environment
tmpdir=$(mktemp -d)
scr=${0##*/}
destdir='/tmp/vault'
 
#created logger functions
loginf() { logger -s -t "$scr" -p "info" "$@" 2>>  /var/log/cron.log; }
logerr() { logger -s -t "$scr" -p "error" "$@" 2>> /var/log/cron.log; }

# created cleanup trap
cleanup() { /bin/rm -rf $tmpdir 2>/dev/null;}

function finish {
  cleanup
}
trap finish EXIT


# create temporary file for the cookie file and error logs
cookiefile=$(mktemp -p $tmpdir)
curlerr=$(mktemp -p $tmpdir)

# ping $SAN_HOST if success move forwards else die a horrible death
if [[ $( ping -c 1 $host > /dev/null 2>&1 ) ]]; then
	OUTPUT="unable to connect; exiting...";
else
	# pull newest git version
	cd /tmp/vault && git pull origin master > /dev/null 2>&1;
	
	# grab the cookie data from nas4free
	curl -LkSs --cookie-jar $cookiefile --data-ascii "username=$user&password=$passwd" "http://$host/login.php" -o /dev/null 2>$curlerr || { logerr "[$host]: download: $(cat $curlerr)"; cleanup; exit 1; }
	
	# also grab XSS authtoken
	auth_token=$( curl -sSk --cookie $cookiefile http://$host/system_backup.php | grep authtoken | sed 's/.*value="\(.*\)".*/\1/' 2>$curlerr || { logerr "[$host]: download: $(cat $curlerr)"; cleanup; exit 1; } )

	# collect backup config
	curl -Ss --cookie $cookiefile --data-ascii "authtoken=$auth_token&Submit=Download configuration" "http://$host/system_backup.php" -o $tmpdir/config.xml.tmp || { logerr "[$host]: logout: $(cat $curlerr)"; cleanup; exit 1; }

	# Logout properly
	curl -s -S -k "http://$host/logout.php" -o /dev/null -b $cookiefile 2>$curlerr || { logerr "[$host]: logout: $(cat $curlerr)"; cleanup; exit 1; }

	# move to working directory to allow for testing for changes
	mv $tmpdir/config.xml.tmp $destdir/config.xml;
	cd $destdir;

	# if changed commit changes to local repo
	OUTPUT=$( git commit -a -m "Cron backup for $(date '+%Y%m%d-%H%M%S')" |tr '\n' ' ' ) 

	# if no changes exit giving $OUTPUT to log else report what happened to $OUTPUT
	if [[ "$OUTPUT" == *"nothing to commit"* ]] && ! [[ "$OUTPUT" == *"Your branch is ahead"* ]]; then
		OUTPUT="nothing to commit";
	        exit 0;
	else
		OUTPUT="$OUTPUT, $( git push -u origin master |tr '\n' ' ' )";
	fi
fi

# report output to STDIN
echo "${OUTPUT}" |tr '\n' ' ';
