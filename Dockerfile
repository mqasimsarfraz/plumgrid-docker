FROM  ubuntu:12.04
MAINTAINER  Qasim Sarfraz qasims@plumgrid.com
ENV  DEBIAN_FRONTEND noninteractive

# Keep upstart from complaining and avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
# Also fix user and group ids before installing any package
RUN dpkg-divert --local --rename --add /sbin/initctl \
&& echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d \
&& ln -sf /bin/true /sbin/initctl && /usr/sbin/groupadd -g 108 ssl-cert -r \
&& /usr/sbin/groupadd -g 109 postgres -r \
&& /usr/sbin/useradd -m -d /var/lib/postgresql -s /bin/bash -c "PostgreSQL administrator" -u 105 -g 109 -G ssl-cert postgres

#Install base dependencies and setup PLUMgrid repos
RUN  apt-get update && apt-get install curl wget openssh-server -y \
&& echo "deb http://192.168.10.167/plumgrid plumgrid unstable" > /etc/apt/sources.list.d/plumgrid.list \
&&  echo "deb http://192.168.10.167/plumgrid-extra plumgrid lxc-autoinstall" >> /etc/apt/sources.list.d/plumgrid.list \
&&  curl -Ls http://192.168.10.167/plumgrid/GPG-KEY | /usr/bin/apt-key add -

#Setup SSH config and root directory
RUN grep -q "^Port 22" /etc/ssh/sshd_config  \
&& sed "s/^Port 22.*/Port 2222/" -i  /etc/ssh/sshd_config \
|| sed "$ a\\Port 2222" -i /etc/ssh/sshd_config \
&& grep -q "^PasswordAuthentication" /etc/ssh/sshd_config  \
&& sed "s/^PasswordAuthentication.*/PasswordAuthentication no/" -i  /etc/ssh/sshd_config \
|| sed "$ a\\PasswordAuthentication no" -i /etc/ssh/sshd_config && grep -q "^UseDNS" /etc/ssh/sshd_config  \
&& sed "s/^UseDNS.*/UseDNS no/" -i  /etc/ssh/sshd_config \
|| sed "$ a\\UseDNS no" -i /etc/ssh/sshd_config \
&& /bin/ln -s /mnt/data/root /root \
&& /bin/ln -s /mnt/data/root/.ssh /root/.ssh \
&& /usr/bin/touch /root/.hushlogin

#Install PLUMgrid Packages
RUN  /usr/bin/apt-get -y update \
&&  /usr/bin/apt-get -y dist-upgrade \
&&  /usr/sbin/locale-gen en_US en_US.UTF-8 \
&&  /usr/sbin/dpkg-reconfigure locales \
&&  /usr/bin/apt-get -y install plumgrid-base plumgrid-ui plumgrid-cli rsyslog plumgrid-sal \
&&  /usr/sbin/update-rc.d postgresql disable \
&&  /etc/init.d/bind9 stop \
&&  /usr/sbin/update-rc.d -f bind9 remove

RUN wget http://192.168.10.167/plumgrid-extra/pool/unstable/libs/libselinux/libselinux1_2.1.13-2_amd64.deb -P /tmp/ \
&&  /usr/bin/dpkg -i /tmp/libselinux1_2.1.13-2_amd64.deb \
&&  rm -rf /tmp/libselinux1_2.1.13-2_amd64.deb

#Setup symlinks for data persistency upon upgrades
RUN /usr/bin/sudo -u postgres /bin/ln -s /mnt/data/postgresql/.postgresql /var/lib/postgresql/.postgresql \
&& /bin/ln -s /mnt/data/conf/pg/plumgrid.conf /opt/pg/etc/plumgrid.conf \
&& /bin/ln -s /mnt/data/conf/pg/ifcs.conf /opt/pg/etc/ifcs.conf \
&& /bin/ln -s /mnt/data/conf/pg/iovisor.ini /opt/pg/etc/iovisor.ini \
&& /bin/ln -s /mnt/data/conf/etc/00-pg.conf /etc/rsyslog.d/00-pg.conf \
&& /bin/ln -s /mnt/data/conf/etc/keepalived.conf /etc/keepalived/keepalived.conf \
&& /bin/ln -fs /mnt/data/conf/pg/nginx.conf /opt/pg/sal/nginx/conf.d/default.conf \
&& /bin/ln -fs /mnt/data/ssl/nginx/default.crt /opt/pg/sal/nginx/ssl/default.crt \
&& /bin/ln -fs /mnt/data/ssl/nginx/default.key /opt/pg/sal/nginx/ssl/default.key \
&& /bin/ln -s /mnt/data/db /opt/pg/db \
&& /bin/ln -s /mnt/data/log /opt/pg/log

#Helper script to launch PLUMgrid processes. It will be removed once part of deb package
ADD launch_docker_helper.sh /opt/pg/scripts
