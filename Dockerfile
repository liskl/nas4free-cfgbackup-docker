FROM centos:centos7
MAINTAINER Loren Lisk <loren.lisk@liskl.com>

ARG GIT_USER_NAME
ARG GIT_USER_EMAIL
ARG CONFIG_REPO_URI

ENV GIT_USER_NAME ${GIT_USER_NAME:-"nas4free-config-backup-service"}
ENV GIT_USER_EMAIL ${GIT_USER_EMAIL:-"nas4free-cfgbak-cron-service@nas4free.example.com"}
ENV CONFIG_REPO_URI ${CONFIG_REPO_URI:-"https://stash.example.com/scm/lcs/san-cfg_backup.git"}

RUN yum -y update && yum -y install git curl cronie && yum -y clean all;

# Add .netrc for passwordless access to stash
COPY cfg-files/root/.netrc /root/.netrc

# update SSL Trust to allow for startssl
RUN cd /etc/pki/ca-trust/source/anchors && curl -Ss -o startssl-ca-bundle.pem http://www.startssl.com/certs/ca-bundle.pem
RUN update-ca-trust

RUN mkdir /tmp/vault
WORKDIR /tmp/
RUN git clone "${CONFIG_REPO_URI}"

# Say who I am (the Service) 
WORKDIR /tmp/vault
RUN git config user.email "${GIT_USER_EMAIL}";
RUN git config user.name "${GIT_USER_NAME}";

# Add crontab file in the cron directory
COPY cfg-files/etc/cron.d/vault-cfgbak-cron /etc/cron.d/vault-cfgbak-cron

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/vault-cfgbak-cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# add the script to complete the backup
COPY cfg-files/usr/local/bin/backup-vault-config.sh /usr/local/bin/backup-vault-config.sh
RUN chmod 0744 /usr/local/bin/backup-vault-config.sh

# Run the command on container startup
CMD env > /root/env.txt && crond && tail -f /var/log/cron.log
