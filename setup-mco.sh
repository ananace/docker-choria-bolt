#!/bin/bash -eu

user="${MCOLLECTIVE_IDENTITY:-gitlab-ci}"

echo "Setting up MCollective client for ${user}..."

mkdir -p ~/.puppetlabs/etc/puppet/ssl/{certs,private_keys}
echo "${MCOLLECTIVE_CERT}" > "$HOME/.puppetlabs/etc/puppet/ssl/certs/${user}.mcollective.pem"
echo "${MCOLLECTIVE_KEY}" > "$HOME/.puppetlabs/etc/puppet/ssl/private_keys/${user}.mcollective.pem"
echo "${MCOLLECTIVE_CA}" > ~/.puppetlabs/etc/puppet/ssl/certs/ca.pem

# Apparently this parameter is not templated correctly
sed -e "s/identity = .*/identity = ${user}/" -i /etc/puppetlabs/mcollective/client.cfg
sed -e "s/identity = .*/identity = ${user}/" -i /etc/puppetlabs/mcollective/choria-shim.cfg
sed -e "s/@NATS@/${MCOLLECTIVE_NATS}/" \
    -e "s/@PUPPETSERVER@/${MCOLLECTIVE_PUPPETSERVER}/" \
    -e "s/@PUPPETCA@/${MCOLLECTIVE_PUPPETCA}/" \
    -e "s/@PUPPETDB@/${MCOLLECTIVE_PUPPETDB}/" \
    -i /etc/puppetlabs/mcollective/plugin.d/choria.cfg
