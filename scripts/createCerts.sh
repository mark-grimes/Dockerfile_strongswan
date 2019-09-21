#! /bin/sh

#
# You need ipsec installed for this to work. The easiest way is probably to use the docker container
# with:
#  docker run --rm -it -v $PWD:/input -w /input strongswan createCerts.sh
#

if [ $# -ne 3 ]; then
	echo "Usage: $0 <server address> <client username> <client password>"
	exit -1
fi

REPLACEME_SERVER_NAME=$1
REPLACEME_USERNAME=$2
REPLACEME_PASSWORD=$3

# Check to see if this is an IP address or domain name. If it's a domain name some
# config settings require "@" in front of it
if echo "$REPLACEME_SERVER_NAME" | grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" > /dev/null; then
	REPLACEME_SERVER_IDENTIFIER=${REPLACEME_SERVER_NAME}
else
	REPLACEME_SERVER_IDENTIFIER="@${REPLACEME_SERVER_NAME}"
fi

# Create directories for the output config
OUTPUT_ROOT="strongswan_${REPLACEME_SERVER_NAME}"
mkdir -p ${OUTPUT_ROOT}/config

# Create configuration files with the correct server name
sed -e s:"REPLACEME_SERVER_NAME":"${REPLACEME_SERVER_NAME}":g \
    -e s:"REPLACEME_SERVER_IDENTIFIER":"${REPLACEME_SERVER_IDENTIFIER}":g \
    -e s:"REPLACEME_USERNAME":"${REPLACEME_USERNAME}":g \
    -e s:"REPLACEME_PASSWORD":"${REPLACEME_PASSWORD}":g \
    ipsec.conf_SKELETON > ${OUTPUT_ROOT}/config/ipsec.conf
sed -e s:"REPLACEME_SERVER_NAME":"${REPLACEME_SERVER_NAME}":g \
    -e s:"REPLACEME_SERVER_IDENTIFIER":"${REPLACEME_SERVER_IDENTIFIER}":g \
    -e s:"REPLACEME_USERNAME":"${REPLACEME_USERNAME}":g \
    -e s:"REPLACEME_PASSWORD":"${REPLACEME_PASSWORD}":g \
    ipsec.secrets_SKELETON > ${OUTPUT_ROOT}/config/ipsec.secrets

# Create a directory for the output server certificates and key
mkdir -p ${OUTPUT_ROOT}/certs

ipsec pki --pub --in vpn-server-key.pem --type rsa \
	| ipsec pki --issue --lifetime 1825 --cacert server-root-ca.pem --cakey server-root-key.pem \
	  --dn "C=UK, O=Grimley Fiendish, CN=${REPLACEME_SERVER_NAME}" --san "${REPLACEME_SERVER_NAME}" --flag serverAuth \
	  --flag ikeIntermediate --outform pem > ${OUTPUT_ROOT}/certs/vpn-server-cert.pem

# Copy the server key too, so that everything is in one place
cp vpn-server-key.pem ${OUTPUT_ROOT}/certs/

echo "If all went well, you should have all required files in ${OUTPUT_ROOT}."
echo "Copy to the server with e.g.:"
echo ""
echo "scp -r -i ~/.ssh/LightsailDefaultKey-eu-west-2.pem ${OUTPUT_ROOT}/ ubuntu@${REPLACEME_SERVER_NAME}:strongswan"
echo ""
