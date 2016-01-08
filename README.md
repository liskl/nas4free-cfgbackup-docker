Description:
	Ever needed to make sure you had a working copy with SVN backups of your nas4free installation? look no further.
	the following tool can be installed in minutes and allows you to enable a ongoing backup within a minute of the
	change occuring.
	
	uses git curl and cron to:
		Login to the nas4free bot at $SAN_HOST using $SAN_USER and $SAN_PASSWD environment variables;
		download the current config.xml using the same functions of the web interface
		then after doing a git pull from $CONFIG_REPO_URI

	NOTE: uses /root/.netrc for git credentials. [needs to be created]
	[root@trance nas4free-cfgbackup]# cat ./cfg-files/root/.netrc
	machine stash.example.com
	login backup-service-account
	password thisisasecretpassword

Use:

DEFINE Environment Variables
	SAN_HOST="nas4free.example.com"
	SAN_USER="EXAMPLE_USER"
	SAN_PASSWD="EXAMPLE_PASSWORD"
	CONFIG_REPO_URI='https://stash.example.com/scm/lcs/config_backup.git'
	GIT_USER_EMAIL='nas4free-cfgbak-cron-service@nas4free.example.com'
	GIT_USER_NAME='nas4free-config-backup-service'

Installation:

create a .netrc at ./cfg-files/root/.netrc containing:

        machine stash.example.com
        login backup-service-account
        password thisisasecretpassword

then build and deploy from ./
	
	docker build -t liskl/nas4free-cfgbak;
	docker run -d -e SAN_HOST='nas4free.example.com' \
                      -e SAN_USER='EXAMPLE_USER' \
                      -e SAN_PASSWD='EXAMPLE_PASSWORD' \
                      -e CONFIG_REPO_URI='https://stash.example.com/scm/lcs/config_backup.git' \
                      -e GIT_USER_EMAIL='nas4free-cfgbak-cron-srv@nas4free.example.com' \
                      -e GIT_USER_NAME='nas4free-config-backup-service' \
                      liskl/nas4free-cfgbak;
