#!/bin/sh
rm /pki/*
set -e -o pipefail
tmp=$(mktemp /tmp/cert-ceremonies.XXXXXX)

# root ca
rslotid_rsa=$(softhsm2-util --init-token --free --label "root signing key (rsa)" --pin 1234 --so-pin 6789 | grep -o "[0-9]*$")
sed "s/{{ .SlotID[ ]\?}}/$rslotid_rsa/g" /opt/boulder/cert-ceremonies/root-ceremony-rsa.yaml >$tmp
ceremony -config $tmp >/dev/null 2>&1 

rslotid_ecdsa=$(softhsm2-util --init-token --free --label "root signing key (ecdsa)" --pin 1234 --so-pin 6789 | grep -o "[0-9]*$")
sed "s/{{ .SlotID[ ]\?}}/$rslotid_ecdsa/g" /opt/boulder/cert-ceremonies/root-ceremony-ecdsa.yaml >$tmp
ceremony -config $tmp >/dev/null 2>&1 

# intermediate ca rsa
slotid=$(softhsm2-util --init-token --free --label "intermediate signing key (rsa)" --pin 1234 --so-pin 6789 | grep -o "[0-9]*$")
sed "s/{{ .SlotID[ ]\?}}/$slotid/g" /opt/boulder/cert-ceremonies/intermediate-key-ceremony-rsa.yaml >$tmp
ceremony -config $tmp >/dev/null 2>&1 

#sed "s/{{ .SlotID[ ]\?}}/$slotid/g" /opt/boulder/cert-ceremonies/intermediate-key-ceremony-rsa.yaml >$tmp
#ceremony -config $tmp >/dev/null

## a
sed "s/{{ .SlotID[ ]\?}}/$rslotid_rsa/g" /opt/boulder/cert-ceremonies/intermediate-ceremony-rsa.yaml | \
  sed "s|{{ .CertPath }}|/pki/intermediate-cert-rsa-a.pem|g" | \
  sed "s/{{ .CommonName }}/$INTERMEDIATE_COMMON_NAME A/g" >$tmp
ceremony -config $tmp >/dev/null 2>&1 

## b
sed "s/{{ .SlotID[ ]\?}}/$rslotid_rsa/g" /opt/boulder/cert-ceremonies/intermediate-ceremony-rsa.yaml | \
  sed "s|{{ .CertPath }}|/pki/intermediate-cert-rsa-b.pem|g" | \
  sed "s/{{ .CommonName }}/$INTERMEDIATE_COMMON_NAME B/g" >$tmp
ceremony -config $tmp >/dev/null 2>&1 

# intermediate ca ecdsa
slotid=$(softhsm2-util --init-token --free --label "intermediate signing key (ecdsa)" --pin 1234 --so-pin 6789 | grep -o "[0-9]*$")
sed "s/{{ .SlotID[ ]\?}}/$slotid/g" /opt/boulder/cert-ceremonies/intermediate-key-ceremony-ecdsa.yaml >$tmp
ceremony -config $tmp >/dev/null 2>&1 

#sed "s/{{ .SlotID[ ]\?}}/$slotid/g" /opt/boulder/cert-ceremonies/intermediate-key-ceremony-ecdsa.yaml >$tmp
#ceremony -config $tmp >/dev/null

## a
sed "s/{{ .SlotID[ ]\?}}/$rslotid_ecdsa/g" /opt/boulder/cert-ceremonies/intermediate-ceremony-ecdsa.yaml | \
  sed "s|{{ .CertPath }}|/pki/intermediate-cert-ecdsa-a.pem|g" | \
  sed "s/{{ .CommonName }}/$INTERMEDIATE_COMMON_NAME A/g" >$tmp
ceremony -config $tmp >/dev/null 2>&1

## b
sed "s/{{ .SlotID[ ]\?}}/$rslotid_ecdsa/g" /opt/boulder/cert-ceremonies/intermediate-ceremony-ecdsa.yaml | \
  sed "s|{{ .CertPath }}|/pki/intermediate-cert-ecdsa-b.pem|g" | \
  sed "s/{{ .CommonName }}/$INTERMEDIATE_COMMON_NAME B/g" >$tmp
ceremony -config $tmp >/dev/null 2>&1

rm $tmp
