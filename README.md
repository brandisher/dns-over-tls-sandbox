# DNS-over-TLS Sandbox
The purpose of this repo is to simplify the process of getting DNS-over-TLS set up using the built-in images in the cluster-dns-operator.

## Setup
_Note: You must be logged into an OpenShift cluster before running `setup.sh`_

Running `./setup.sh` will...

1. Create the certificates
2. Create the Configmap that holds the Corefile, server-cert.pem, server-key.pem, and ca-cert.pem values
3. Create the upstream service and upstream pod. This uses the Template type to ensure that everything we pass in is consistent.

This script will also create a service signed by the service-signer on the cluster that can be used to simulate connecting
to a third party DNS resolver.

## Testing

To validate that the upstream resolver is running with TLS enabled, do the following:
1. `oc rsh openssl-client`
2. `openssl s_client -connect upstream-tls:5353 -servername upstream-tls`

Optionally, you can pass `-CAfile /tmp/ca-cert.pem` to validate that the server cert of the upstream was signed by 
the CA cert on the client.
