#!/bin/bash

UPSTREAM=upstream-tls
DNSPORT=5353
PODDNSPORT=5353

CAKEY=ca.key
CACERT=ca-cert.pem

SERVERKEY=server.key
SERVERCERT=server-cert.pem
SERVERCERTCSR=server.csr

# Generate CA and Server keys
openssl genrsa 2048 > $CAKEY
openssl genrsa 2048 > $SERVERKEY

# Create the CA cert
openssl req -new -x509 -nodes -days 365 -key $CAKEY -out $CACERT -subj "/C=US/ST=NC/L=Raleigh/O=Global/OU=Global/CN=sample-ca"

# Create the CSR
openssl req -new -nodes -key $SERVERKEY -out $SERVERCERTCSR -config san.conf

# Create the Server cert
openssl x509 -req -days 365 -set_serial 01 -in $SERVERCERTCSR -out $SERVERCERT -CA $CACERT -CAkey $CAKEY -extfile san.conf -extensions v3_req

COREDNS_IMAGE=$(oc get co/dns -o jsonpath='{.status.versions[?(@.name=="coredns")].version}')
OC_IMAGE=$(oc get co/dns -o jsonpath='{.status.versions[?(@.name=="openshift-cli")].version}')

cat >Corefile <<EOF
tls://.:$PODDNSPORT {
  hosts {
    1.2.3.4 www.foo.com
  }
  tls /etc/coredns/server-cert.pem /etc/coredns/server.key
  health
  errors
  log
  reload
}
EOF

oc create namespace $UPSTREAM
oc project $UPSTREAM
oc label ns/$UPSTREAM security.openshift.io/scc.podSecurityLabelSync=false security.kubernetes.io/enforce=privileged security.kubernetes.io/warn=privileged security.kubernetes.io/audit=privileged
oc create configmap "$UPSTREAM" --from-file="Corefile" --from-file=$SERVERCERT --from-file=$SERVERKEY --from-file=$CACERT
oc process -f upstream.yaml NAME=$UPSTREAM IMAGE=$COREDNS_IMAGE CLI=$OC_IMAGE --local | oc apply -f -
oc process -f upstream-service-ca.yaml NAME=$UPSTREAM IMAGE=$COREDNS_IMAGE CLI=$OC_IMAGE --local | oc apply -f -
