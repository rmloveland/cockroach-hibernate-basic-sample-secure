CERTS_DIR = /tmp/certs

all: run clean

run: privs
	gradle run

privs: database
	cockroach sql --certs-dir=$(CERTS_DIR) -e 'GRANT ALL ON DATABASE bank TO maxroach'

database: user
	cockroach sql --certs-dir=$(CERTS_DIR) -e 'CREATE DATABASE bank'

user: cluster
	cockroach user --certs-dir=$(CERTS_DIR) set maxroach --password && sleep 5

cluster: convert-certs
	perl bin/start-local-cluster --nodes=3 --secure

convert-certs: certs
	cd $(CERTS_DIR) && \
	openssl x509 -in node.crt -inform pem -outform der -out node.der && \
	openssl pkcs8 -topk8 -inform PEM -outform DER -in node.key -out node.key.pk8 -nocrypt

certs:
	perl bin/gen-cluster-certs src/main/resources/certs.conf

clean:
	perl bin/stop-local-cluster && rm -rf $(CERTS_DIR)

update-deps:
	cp ${HOME}/work/code/start-local-cluster/start-local-cluster.pl bin/start-local-cluster && \
	cp ${HOME}/work/code/start-local-cluster/stop-local-cluster.pl bin/stop-local-cluster && \
	cp ${HOME}/work/code/gen-certs/gen-cluster-certs bin/gen-cluster-certs && \
	chmod -R 755 bin
