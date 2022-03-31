#!/bin/bash

UPSTREAM=upstream-tls
DNSPORT=5353
PODDNSPORT=5353

# TLS
# https://mariadb.com/docs/security/encryption/in-transit/create-self-signed-certificates-keys-openssl/
openssl genrsa 2048 > ca-key.pem
openssl req -new -x509 -nodes -days 365000 -key ca-key.pem -out ca-cert.pem -subj "/C=US/ST=NC/L=Raleigh/O=Global/OU=Global/CN=$UPSTREAM.$UPSTREAM.svc.cluster.local"
openssl req -newkey rsa:2048 -nodes -days 365000 -keyout server-key.pem -out server-req.pem -subj "/C=US/ST=NC/L=Raleigh/O=Global/OU=Global/CN=$UPSTREAM.$UPSTREAM.svc.cluster.local"
openssl x509 -req -days 365000 -set_serial 01 -in server-req.pem -out server-cert.pem -CA ca-cert.pem -CAkey ca-key.pem


COREDNS_IMAGE=$(oc get co/dns -o jsonpath='{.status.versions[?(@.name=="coredns")].version}')

cat >Corefile <<EOF
.:$PODDNSPORT {
  hosts {
    1.2.3.4 www.foo.com
  }
  tls /etc/coredns/server-cert.pem /etc/coredns/server-key.pem
  health
  errors
  log
}
EOF

oc create namespace $UPSTREAM
oc project $UPSTREAM
oc create configmap "$UPSTREAM" --from-file="Corefile" --from-file="server-cert.pem" --from-file="server-key.pem"
oc process -f upstream.yaml NAME=$UPSTREAM IMAGE=$COREDNS_IMAGE --local | oc apply -f -
