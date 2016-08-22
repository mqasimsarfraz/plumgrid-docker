FROM  ubuntu:12.04
MAINTAINER  Qasim Sarfraz qasims@plumgrid.com
ENV  DEBIAN_FRONTEND noninteractive

# Keep upstart from complaining and avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
#Install base dependencies and setup PLUMgrid repos
RUN dpkg-divert --local --rename --add /sbin/initctl \
&& echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d \
&& /usr/bin/apt-get -y update \
&& /usr/bin/apt-get -y install curl bc openssh-server supervisor --no-install-recommends \
&& echo "deb http://192.168.10.167/plumgrid plumgrid unstable" > /etc/apt/sources.list.d/plumgrid.list \
&& echo "deb http://192.168.10.167/plumgrid-extra plumgrid lxc-autoinstall" >> /etc/apt/sources.list.d/plumgrid.list \
&& curl -Ls http://192.168.10.167/plumgrid/GPG-KEY | /usr/bin/apt-key add - \
&& curl -Ls http://192.168.10.167/plumgrid/GPG-KEY | /usr/bin/apt-key add - \
&& rm -rf /var/lib/apt/lists/* \
&& rm -rf /var/cache/apt/*

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
&& /usr/bin/touch /root/.hushlogin \
&& mkdir -p /var/run/sshd

#Install PLUMgrid Packages
RUN /usr/bin/apt-get -y update \
&&  /usr/bin/apt-get -y dist-upgrade \
&&  /usr/sbin/locale-gen en_US en_US.UTF-8 \
&&  /usr/sbin/dpkg-reconfigure locales \
&&  /usr/bin/apt-get -y install plumgrid-edge --no-install-recommends \
&&  rm -rf /etc/apt/sources.list.d/plumgrid.list \
&&  rm -rf /var/lib/apt/lists/* \
&& rm -rf /var/cache/apt/*

RUN curl -O http://192.168.10.167/plumgrid-extra/pool/unstable/libs/libselinux/libselinux1_2.1.13-2_amd64.deb \
&& /usr/bin/dpkg -i libselinux1_2.1.13-2_amd64.deb \
&&  rm -rf libselinux1_2.1.13-2_amd64.deb

#Setup symlinks for data persistency upon upgrades
RUN /bin/mkdir -p /opt/pg/etc \
&& /bin/ln -s /mnt/data/conf/pg/plumgrid.conf /opt/pg/etc/plumgrid.conf \
&& /bin/ln -s /mnt/data/conf/pg/ifcs.conf /opt/pg/etc/ifcs.conf \
&& /bin/ln -s /mnt/data/conf/etc/00-pg.conf /etc/rsyslog.d/00-pg.conf

#Add startup scripts
ADD start_plumgrid_edge /opt/pg/bin/
ADD start_fabric_monitor /opt/pg/bin/
ADD start_rsyslog /opt/pg/bin/
ADD supervisor-plumgrid-edge.conf /etc/supervisor/conf.d

#Startup command of plumgrid-edge container
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisor-plumgrid-edge.conf"]
