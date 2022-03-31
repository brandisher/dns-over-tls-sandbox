# DNS-over-TLS Sandbox

## Setup
Running `./setup.sh` will...

1. Create the certificates
2. Create the Configmap that holds the Corefile, server-cert.pem, and server-key.pem values
3. Create the upstream service and upstream pod. This uses the Template type to ensure that everything we pass in is consistent.

## Testing
I've been using `oc debug upstream-tls` for testing with reasonable success. At the time of writing I was able to resolve the sample www.foo.com host via the upstream.

```
sh-4.4# dig www.foo.com @172.30.97.45 -p 5353 +tcp +short
1.2.3.4
```

## Running Notes
* We need to investigate kdig (or some other tool) for testing DNS-over-TLS of the upstream. The testing path is likely using the CA cert along with kdig to validate the server cert in the upstream.
