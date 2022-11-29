#!/bin/bash -eu

# Ensure USER has a usable value assigned
[ -n "$MCOLLECTIVE_IDENTITY" ] && export USER="${MCOLLECTIVE_IDENTITY}" || true
[ -z "$USER" ] && export USER="gitlab-ci" || true

echo "Setting up MCollective client for ${USER}..."

mkdir -p ~/.puppetlabs/etc/puppet/ssl/{certs,private_keys}
echo "${MCOLLECTIVE_CERT}" > "$HOME/.puppetlabs/etc/puppet/ssl/certs/${USER}.mcollective.pem"
echo "${MCOLLECTIVE_KEY}" > "$HOME/.puppetlabs/etc/puppet/ssl/private_keys/${USER}.mcollective.pem"
echo "${MCOLLECTIVE_CA}" > ~/.puppetlabs/etc/puppet/ssl/certs/ca.pem

# Apparently this parameter is not templated correctly
sed -e "s/identity = .*/identity = ${USER}/" -i /etc/choria/client.conf
sed -e "s/identity = .*/identity = ${USER}/" -i /etc/choria/choria-shim.cfg
# Fill in placeholders in choria configuration
sed -e "s/@NATS@/${MCOLLECTIVE_NATS}/" \
    -e "s/@PUPPETSERVER@/${MCOLLECTIVE_PUPPETSERVER}/" \
    -e "s/@PUPPETCA@/${MCOLLECTIVE_PUPPETCA}/" \
    -e "s/@PUPPETDB@/${MCOLLECTIVE_PUPPETDB}/" \
    -i /etc/choria/plugin.d/choria.cfg
