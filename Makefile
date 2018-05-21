all: run clean

run: privs
	gradle run

privs: database
	cockroach sql --insecure -e 'GRANT ALL ON DATABASE bank TO maxroach'

database: user
	cockroach sql --insecure -e 'CREATE DATABASE bank'

user: cluster
	cockroach user set maxroach --insecure

cluster:
	start-local-cluster --nodes=3

clean:
	stop-local-cluster
