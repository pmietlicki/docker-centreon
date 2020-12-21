FROM centos
MAINTAINER pmietlicki <pmietlicki@gmail.com>

# Update CentOS
RUN yum -y update

# Install Centreon Repository
RUN yum -y install https://yum.centreon.com/standard/3/stable/noarch/RPMS/ces-release-3.0-1.noarch.rpm

# Install centreon
RUN yum -y install mariadb-server && runuser -u mysql /usr/libexec/mysqld start 
RUN yum -y install centreon centreon-base-config-centreon-engine centreon-installed centreon-clapi && runuser -u mysql /usr/libexec/mysqld stop

# Install Widgets
RUN yum -y install centreon-widget-graph-monitoring centreon-widget-host-monitoring centreon-widget-service-monitoring centreon-widget-hostgroup-monitoring centreon-widget-servicegroup-monitoring

# Fix pass in db
ADD scripts/cbmod.sql /tmp/cbmod.sql
RUN runuser -u mysql /usr/libexec/mysqld start && sleep 5 
RUN mysql centreon < /tmp/cbmod.sql && /usr/bin/centreon -u admin -p centreon -a POLLERGENERATE -v 1 && /usr/bin/centreon -u admin -p centreon -a CFGMOVE -v 1 && runuser -u mysql /usr/libexec/mysqld stop

# Set rights for setuid
RUN chown root:centreon-engine /usr/lib/nagios/plugins/check_icmp
RUN chmod -w /usr/lib/nagios/plugins/check_icmp
RUN chmod u+s /usr/lib/nagios/plugins/check_icmp

# Install and configure supervisor
RUN yum -y install python3-setuptools
RUN easy_install-3.6 supervisor

# Todo better split file
ADD scripts/supervisord.conf /etc/supervisord.conf

# Expose 80 for the httpd service.
EXPOSE 80

# Make them easier to snapshot and backup.
VOLUME ["/usr/share/centreon/", "/usr/lib/nagios/plugins/", "/var/lib/mysql"]

# Must use double quotes for json formatting.
CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]
