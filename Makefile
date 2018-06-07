TMP_DIR			= /tmp
CERTS_DIR		= $(TMP_DIR)/certs
JAVA_CERT_ALIAS = cockroach

all: run

run: create-database
	gradle run

create-database: create-cluster
	cockroach sql --certs-dir=$(CERTS_DIR) -e "CREATE USER IF NOT EXISTS maxroach" && \
    cockroach sql --certs-dir=$(CERTS_DIR) -e 'CREATE DATABASE bank' && \
    cockroach sql --certs-dir=$(CERTS_DIR) -e 'GRANT ALL ON DATABASE bank TO maxroach'

create-cluster: convert-java-certs
	perl bin/start-local-cluster --secure --nodes=3

convert-java-certs: gen-certs
	cd $(CERTS_DIR) && \
	openssl pkcs8 -topk8 -inform PEM -outform DER -in client.maxroach.key -out client.maxroach.pk8 -nocrypt && \
	openssl x509 -in ca.crt -inform pem -outform der -out ca.der

gen-certs:
	perl bin/gen-cluster-certs -config=./src/main/resources/certs.conf

clean:
	rm -rf $(CERTS_DIR) && \
	rm -rf $(TMP_DIR)/node* && \
    perl bin/stop-local-cluster && \
	gradle clean

# Internal

copy-deps:
	cp ~/bin/gen-cluster-certs ./bin/ && \
	cp ~/bin/start-local-cluster ./bin/ && \
	cp ~/bin/stop-local-cluster ./bin/

add-java-cert:
	sudo keytool -importcert -v -trustcacerts -alias $(JAVA_CERT_ALIAS) -file $(CERTS_DIR)/ca.der -keystore $$JAVA_HOME/jre/lib/security/cacerts -storepass changeit -noprompt

remove-java-cert:
	sudo keytool -v -delete -alias $(JAVA_CERT_ALIAS) -file $(CERTS_DIR)/ca.der -keystore $$JAVA_HOME/jre/lib/security/cacerts -storepass changeit -noprompt
