#!/bin/bash

UPSTREAM=upstream-tls
DNSPORT=5353
PODDNSPORT=5353

# TLS
openssl genrsa 2048 > ca-key.pem
openssl req -new -x509 -nodes -days 365 -key ca-key.pem -out ca-cert.pem -subj "/C=US/ST=NC/L=Raleigh/O=Global/OU=Global/CN=sample-ca"
openssl req -newkey rsa:2048 -nodes -days 365 -keyout server-key.pem -out server-req.pem -subj "/C=US/ST=NC/L=Raleigh/O=Global/OU=Global/CN=$UPSTREAM.$UPSTREAM.svc.cluster.local"
openssl x509 -req -days 365 -set_serial 01 -in server-req.pem -out server-cert.pem -CA ca-cert.pem -CAkey ca-key.pem

COREDNS_IMAGE=$(oc get co/dns -o jsonpath='{.status.versions[?(@.name=="coredns")].version}')
OC_IMAGE=$(oc get co/dns -o jsonpath='{.status.versions[?(@.name=="openshift-cli")].version}')

cat >Corefile <<EOF
tls://.:$PODDNSPORT {
  hosts {
    1.2.3.4 www.foo.com
  }
  tls /etc/coredns/server-cert.pem /etc/coredns/server-key.pem
  health
  errors
  log
  reload
}
EOF

oc create namespace $UPSTREAM
oc project $UPSTREAM
oc create configmap "$UPSTREAM" --from-file="Corefile" --from-file="server-cert.pem" --from-file="server-key.pem" --from-file="ca-cert.pem"
oc process -f upstream.yaml NAME=$UPSTREAM IMAGE=$COREDNS_IMAGE CLI=$OC_IMAGE --local | oc apply -f -
