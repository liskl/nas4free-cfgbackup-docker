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
 
loginf() { logger -s -t "$scr" -p "info" "$@" 2>>  /var/log/cron.log; }
logerr() { logger -s -t "$scr" -p "error" "$@" 2>> /var/log/cron.log; }
cleanup() { /bin/rm -rf $tmpdir 2>/dev/null;}

function finish {
  cleanup
}
trap finish EXIT

cookiefile=$(mktemp -p $tmpdir)
curlerr=$(mktemp -p $tmpdir)

if [[ $( ping -c 1 vault-mgmt.liskl.com > /dev/null 2>&1 ) ]]; then
  echo "unable to connect; exiting...";
else

	cd /tmp/vault && git pull origin master > /dev/null 2>&1;
	curl -LkSs --cookie-jar $cookiefile --data-ascii "username=$user&password=$passwd" "http://$host/login.php" -o /dev/null 2>$curlerr || { logerr "[$host]: download: $(cat $curlerr)"; cleanup; exit 1; }
	auth_token=$( curl -sSk --cookie $cookiefile http://$host/system_backup.php | grep authtoken | sed 's/.*value="\(.*\)".*/\1/' 2>$curlerr || { logerr "[$host]: download: $(cat $curlerr)"; cleanup; exit 1; } )
	curl -Ss --cookie $cookiefile --data-ascii "authtoken=$auth_token&Submit=Download configuration" "http://$host/system_backup.php" -o $tmpdir/config.xml.tmp || { logerr "[$host]: logout: $(cat $curlerr)"; cleanup; exit 1; }
	curl -s -S -k "http://$host/logout.php" -o /dev/null -b $cookiefile 2>$curlerr || { logerr "[$host]: logout: $(cat $curlerr)"; cleanup; exit 1; }

	mv $tmpdir/config.xml.tmp $destdir/config.xml;

	cd $destdir;

	OUTPUT=$( git commit -a -m "Cron backup for $(date '+%Y%m%d-%H%M%S')" |tr '\n' ' ' ) 

	if [[ "$OUTPUT" == *"nothing to commit"* ]]; then
	        exit 0;
	else
		OUTPUT="$OUTPUT, $( git push -u origin master |tr '\n' ' ' )";

	fi
fi

echo "$OUTPUT"
