# CockroachDB Hibernate Basic Sample - Secure (tm)

NOTE: this is unofficial - no warranties.

Manual instructions:

1. Create certs for the cluster

        $ cockroach cert create-ca --certs-dir=/tmp/certs --ca-key=/tmp/certs/ca.key
        $ cockroach cert create-node localhost --certs-dir=/tmp/certs --ca-key=/tmp/certs/ca.key --overwrite
        $ cockroach cert create-client root --certs-dir=/tmp/certs --ca-key=/tmp/certs/ca.key

2. Start a local 3-node cluster

        $ cockroach start --certs-dir=/tmp/certs --store=/tmp/node0 --host=localhost --port=26257 --http-port=8888  --join=localhost:26257,localhost:26258,localhost:26259
        $ cockroach start --certs-dir=/tmp/certs --store=/tmp/node1 --host=localhost --port=26258 --http-port=8889  --join=localhost:26257,localhost:26258,localhost:26259
        $ cockroach start --certs-dir=/tmp/certs --store=/tmp/node2 --host=localhost --port=26259 --http-port=8890  --join=localhost:26257,localhost:26258,localhost:26259

3. Initialize the cluster

        $ cockroach init --certs-dir=/tmp/certs --host=localhost --port=26257

3. Make user maxroach

        > CREATE USER IF NOT EXISTS maxroach;

4. Create the bank database

        > CREATE DATABASE bank;

5. Grant permissions to user 'maxroach' on the bank database

        > GRANT ALL ON DATABASE bank TO maxroach;

6. Make a client cert for maxroach using the root CA

        $ cockroach cert create-client maxroach --certs-dir=/tmp/certs --ca-key=/tmp/certs/ca.key

7. Verify the client cert using OpenSSL

        $ cd /tmp/certs
        $ openssl verify -CAfile ca.crt -purpose sslclient client.maxroach.crt 
        client.maxroach.crt: OK

8. Convert the maxroach client cert to the Java pk8 format

        $ cd /tmp/certs
        $ openssl x509 -in client.maxroach.crt -inform pem -outform der -out client.maxroach.der
        $ openssl pkcs8 -topk8 -inform PEM -outform DER -in client.maxroach.key -out client.maxroach.pk8 -nocrypt

9. Run the Java code

        $ gradle run
