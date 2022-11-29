FROM debian:11

ENV MCOLLECTIVE_IDENTITY=gitlab-ci
COPY hiera/ /etc
COPY hiera.yaml /etc

RUN apt-get update -yqq \
 && apt-get install curl ca-certificates -yqq --no-install-recommends \
\
 && curl -JLO https://apt.puppet.com/puppet7-release-bullseye.deb \
 && dpkg -i puppet7-release-*.deb \
 && rm puppet7-release-*.deb \
\
 && apt-get update -yqq \
 && apt-get install puppet-agent -yqq \
 && echo "Testing hiera functionality;" \
 && echo "choria::server: $(/opt/puppetlabs/bin/hiera -c /etc/hiera.yaml choria::server)" \
 && test "$(/opt/puppetlabs/bin/hiera -c /etc/hiera.yaml choria::server)" = "false" \
 && ln -s /bin/true /usr/bin/systemctl \
 && ln -s /bin/true /usr/bin/crontab \
 && /opt/puppetlabs/bin/puppet module install puppetlabs-cron_core --target-dir=/tmp/modules \
 && /opt/puppetlabs/bin/puppet module install choria-choria --target-dir=/tmp/modules \
 && /opt/puppetlabs/bin/puppet module install choria-mcollective_agent_bolt_tasks --target-dir=/tmp/modules \
 && /opt/puppetlabs/bin/puppet apply --hiera_config=/etc/hiera.yaml --modulepath=/tmp/modules -e 'class { "choria": server => false, }' \
\
 && cp -r /tmp/modules/mcollective_choria/files/mcollective/* /opt/puppetlabs/mcollective/plugins/mcollective/ \
 && cp -r /tmp/modules/mcollective_agent_*/files/mcollective/* /opt/puppetlabs/mcollective/plugins/mcollective/ \
 && echo 'bWlkZGxld2FyZV9ob3N0cyA9IEBOQVRTQApwdXBwZXRjYV9ob3N0ID0gQFBVUFBFVENBQApwdXBwZXRjYV9wb3J0ID0gODE0MApwdXBwZXRkYl9ob3N0ID0gQFBVUFBFVERCQApwdXBwZXRkYl9wb3J0ID0gODA4MQpwdXBwZXRzZXJ2ZXJfaG9zdCA9IEBQVVBQRVRTRVJWRVJACnB1cHBldHNlcnZlcl9wb3J0ID0gODE0MAo=' | base64 -d > /etc/puppetlabs/mcollective/plugin.d/choria.cfg \
 && apt-get remove curl ca-certificates -yqq \
 && apt-get autoremove -yqq \
 && apt-get clean \
 && rm -rf /tmp/hiera /tmp/modules /var/lib/apt/lists/* \
 && rm /usr/bin/systemctl /usr/bin/crontab \
 && adduser --disabled-password --gecos '' $MCOLLECTIVE_IDENTITY \
 && chown -R $MCOLLECTIVE_IDENTITY /etc/puppetlabs/mcollective

COPY setup-mco.sh /usr/local/bin/setup-mco
COPY entrypoint.sh /usr/local/bin/entrypoint

USER $MCOLLECTIVE_IDENTITY
WORKDIR /home/$MCOLLECTIVE_IDENTITY
ENTRYPOINT ["/usr/local/bin/entrypoint"]
