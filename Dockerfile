FROM phusion/baseimage:0.9.17
MAINTAINER Anatoly Bubenkov "bubenkoff@gmail.com"

ENV HOME /root

# enable ssh
RUN rm -f /etc/service/sshd/down

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN apt-get update

RUN apt-get install -y openssh-server wget lsb-release sudo
RUN \
    export release=`lsb_release -cs` \
    && wget http://apt.puppetlabs.com/puppetlabs-release-$release.deb -O puppetlabs-release-$release.deb \
    && dpkg -i puppetlabs-release-$release.deb \
    && apt-get update \
    && apt-get install puppet -y

EXPOSE 22
EXPOSE 3000

RUN mkdir -p /var/run/sshd
RUN chmod 0755 /var/run/sshd

# Create and configure vagrant user
RUN useradd --create-home -s /bin/bash vagrant
WORKDIR /home/vagrant

# Configure SSH access
RUN mkdir -p /home/vagrant/.ssh
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" > /home/vagrant/.ssh/authorized_keys
RUN chown -R vagrant: /home/vagrant/.ssh
RUN echo -n 'vagrant:vagrant' | chpasswd

# Enable passwordless sudo for the "vagrant" user
RUN mkdir -p /etc/sudoers.d
RUN install -b -m 0440 /dev/null /etc/sudoers.d/vagrant
RUN echo 'vagrant ALL=NOPASSWD: ALL' >> /etc/sudoers.d/vagrant

# Install rmagic
RUN apt-get update
RUN apt-get install -y imagemagick libmagickwand-dev

# Install rvm & ruby
RUN su vagrant -c "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3" 
RUN su vagrant -c "curl -sSL https://get.rvm.io | bash -s stable --ruby" 
RUN echo 'gem: --no-document' > /home/vagrant/.gemrc

# Install nvm & node
RUN su vagrant -c "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | bash \
    && source /home/vagrant/.nvm/nvm.sh \
    && nvm install node \
    && nvm alias default node \
    && nvm use default"

# Install postgresql
RUN apt-get install -y postgresql postgresql-contrib libpq-dev

# Install mysql
RUN echo 'mysql-server mysql-server/root_password password ' | debconf-set-selections
RUN echo 'mysql-server mysql-server/root_password_again password ' | debconf-set-selections
RUN apt-get install -y mysql-server libmysqlclient-dev

# Clean up APT when done.

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
