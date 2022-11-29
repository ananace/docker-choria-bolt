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
 && cp /etc/hiera.yaml /etc/puppetlabs/puppet/hiera.yaml \
 && echo "Testing hiera functionality;" \
 && echo "choria::server: $(/opt/puppetlabs/bin/hiera choria::server)" \
 && test "$(/opt/puppetlabs/bin/hiera -c /etc/hiera.yaml choria::server)" = "false" \
 && ln -s /bin/true /usr/bin/systemctl \
 && ln -s /bin/true /usr/bin/crontab \
 && /opt/puppetlabs/bin/puppet module install puppetlabs-cron_core --target-dir=/tmp/modules \
 && /opt/puppetlabs/bin/puppet module install choria-choria --target-dir=/tmp/modules \
 && /opt/puppetlabs/bin/puppet module install choria-mcollective_agent_bolt_tasks --target-dir=/tmp/modules \
 && /opt/puppetlabs/bin/puppet apply --hiera_config=/etc/hiera.yaml --modulepath=/tmp/modules -e 'include mcollective' \
\
 && cp -r /tmp/modules/mcollective_choria/files/mcollective/* /opt/puppetlabs/mcollective/plugins/mcollective/ \
 && cp -r /tmp/modules/mcollective_agent_*/files/mcollective/* /opt/puppetlabs/mcollective/plugins/mcollective/ \
 && apt-get remove curl ca-certificates -yqq \
 && apt-get autoremove -yqq \
 && apt-get clean \
 && rm -rf /tmp/hiera /tmp/modules /var/lib/apt/lists/* \
 && rm /usr/bin/systemctl /usr/bin/crontab \
 && mkdir -p /etc/puppetlabs/mcollective/plugin.d \
 && adduser --disabled-password --gecos '' $MCOLLECTIVE_IDENTITY \
 && chown -R $MCOLLECTIVE_IDENTITY /etc/puppetlabs/mcollective

ADD choria.cfg /etc/puppetlabs/mcollective/plugin.d/choria.cfg 
ADD setup-mco.sh /usr/local/bin/setup-mco
ADD entrypoint.sh /usr/local/bin/entrypoint

USER $MCOLLECTIVE_IDENTITY
WORKDIR /home/$MCOLLECTIVE_IDENTITY
ENTRYPOINT ["/usr/local/bin/entrypoint"]
