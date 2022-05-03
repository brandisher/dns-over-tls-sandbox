#!/bin/bash

UPSTREAM=upstream-tls

oc project default
oc delete project $UPSTREAM --now
rm *.pem *.key *.csr
rm Corefile
