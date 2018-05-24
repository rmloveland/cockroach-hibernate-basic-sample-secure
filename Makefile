TMP_DIR			= /tmp
CERTS_DIR		= $(TMP_DIR)/certs
JAVA_CERT_ALIAS	= cockroach
USERNAME		= rich
CLUSTER_NAME	= $(USERNAME)-java-ssl-test

# how to get this automagically?
# perhaps you will need to grep the IPs from the output of `roachprod create`?
GATEWAY_NODE_IP=

all: run clean

run: privs
	gradle run

privs: database
    roachprod sql $(CLUSTER_NAME):1 --secure -- -e 'GRANT ALL ON DATABASE bank TO maxroach'

database: user
    roachprod sql $(CLUSTER_NAME):1 --secure -- -e 'CREATE DATABASE bank'

user: store-certs
	roachprod sql $(CLUSTER_NAME):1 --secure -- -e "CREATE USER IF NOT EXISTS maxroach WITH PASSWORD 'foo'"

store-certs: convert-certs
	sudo keytool -importcert -v -trustcacerts -alias $(JAVA_CERT_ALIAS) -file $(CERTS_DIR)/node.der -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit -noprompt

convert-certs: unwrap-certs
	cd $(CERTS_DIR) && \
	openssl x509 -in node.crt -inform pem -outform der -out node.der && \
	openssl pkcs8 -topk8 -inform PEM -outform DER -in node.key -out node.key.pk8 -nocrypt

unwrap-certs: fetch-certs
	cd $(TMP_DIR) && tar xvf certs.tar

fetch-certs: start-cluster
	cd $(TMP_DIR) && roachprod get $(CLUSTER_NAME):1 certs.tar

start-cluster: push-binaries
	roachprod start $(CLUSTER_NAME) --secure

push-binaries: fetch-binaries
	cd $(TMP_DIR) && \
    roachprod put $(CLUSTER_NAME) cockroach-v2.0.2.linux-amd64/cockroach

fetch-binaries: create-cluster
	cd $(TMP_DIR) && \
	wget -qO- https://binaries.cockroachdb.com/cockroach-v2.0.2.linux-amd64.tgz | tar  xvz

create-cluster:
	roachprod create $(CLUSTER_NAME)

clean: remove-temp-cert
	roachprod destroy $(CLUSTER_NAME) && \
	rm -rf $(CERTS_DIR)

remove-temp-cert:
	sudo keytool -v -delete -alias $(JAVA_CERT_ALIAS) -file /tmp/certs/node.der -keystore $$JAVA_HOME/jre/lib/security/cacerts -storepass changeit -noprompt
