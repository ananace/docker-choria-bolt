FROM debian:11

ENV MCOLLECTIVE_IDENTITY=gitlab-ci
ADD hiera/ /etc/hiera/
ADD hiera.yaml /etc

RUN set -x \
 && apt-get update -yqq \
 && apt-get install curl ca-certificates -yqq --no-install-recommends \
\
 && curl -JLO https://apt.puppet.com/puppet7-release-bullseye.deb \
 && dpkg -i puppet7-release-*.deb \
 && rm puppet7-release-*.deb \
\
 && apt-get update -yqq \
 && apt-get install puppet-agent -yqq \
\
 && mv /etc/hiera.yaml /etc/puppetlabs/puppet/hiera.yaml \
 && echo "[main]" >> /etc/puppetlabs/puppet/puppet.conf \
 && echo "hiera_config = /etc/puppetlabs/puppet/hiera.yaml" >> /etc/puppetlabs/puppet/puppet.conf \
\
 && echo "Testing hiera functionality;" \
 && echo "choria::server: $(/opt/puppetlabs/bin/hiera choria::server) (should be false)" \
 && test "$(/opt/puppetlabs/bin/hiera choria::server)" = "false" \
\
 && ln -s /bin/true /usr/bin/systemctl \
 && ln -s /bin/true /usr/bin/crontab \
 && /opt/puppetlabs/bin/puppet module install puppetlabs-cron_core --target-dir=/tmp/modules \
 && /opt/puppetlabs/bin/puppet module install choria-choria --target-dir=/tmp/modules \
 && /opt/puppetlabs/bin/puppet module install choria-mcollective_agent_bolt_tasks --target-dir=/tmp/modules \
 && /opt/puppetlabs/bin/puppet apply --modulepath=/tmp/modules -e 'include mcollective' \
\
 && cp -r /tmp/modules/mcollective_choria/files/mcollective/* /opt/puppetlabs/mcollective/plugins/mcollective/ \
 && cp -r /tmp/modules/mcollective_agent_*/files/mcollective/* /opt/puppetlabs/mcollective/plugins/mcollective/ \
 && apt-get remove curl ca-certificates -yqq \
 && apt-get autoremove -yqq \
 && apt-get clean \
 && rm -rf /tmp/hiera /tmp/modules /var/lib/apt/lists/* \
 && rm /usr/bin/systemctl /usr/bin/crontab \
\
 && mkdir -p /etc/choria/plugin.d \
 && adduser --disabled-password --gecos '' $MCOLLECTIVE_IDENTITY \
 && chown -R $MCOLLECTIVE_IDENTITY /etc/choria

ADD choria.cfg /etc/choria/plugin.d/choria.cfg 
ADD setup-mco.sh /usr/local/bin/setup-mco
ADD entrypoint.sh /usr/local/bin/entrypoint

USER $MCOLLECTIVE_IDENTITY
WORKDIR /home/$MCOLLECTIVE_IDENTITY
ENTRYPOINT ["/usr/local/bin/entrypoint"]
