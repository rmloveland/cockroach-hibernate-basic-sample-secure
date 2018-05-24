# CockroachDB Hibernate Basic Sample - Secure (tm)

**NOTE #1**: This doesn't actually work yet.  Right now it's trying to
capture a description of tasks in the Makefile.  There is still work
to do here.

**NOTE #2**: This is not an official repo of Cockroach Labs.  I work
there, but this is me trying to figure some things out before they
make their way into the actual docs.  For officially supported
content, [read the docs](https://www.cockroachlabs.com/docs).

This repo has an example of how to connect to a CockroachDB cluster
from Java using Hibernate.

## HOW IT WORKS

At a high level, this is a Java project with a Makefile that drives
the following steps:

1. Uses `roachprod` to spin up a new secure cluster

2. Pulls down a `cockroach` binary from the website

3. Copies the cluster's certs to the local disk and munges them with
   `openssl` and `keytool` to make Java happy (maybe)

4. Sets up a small example DB

5. Runs Java code to connect to and update the `bank` DB with some
   `account` objects (via Hibernate)

For exact details of its operation, see the Makefile.

## CAVEATS

As noted above, this doesn't quite work yet.  And it definitely isn't ready for
someone else to use.  For example, it uses some hardcoded variables
such as my username.  Right now the Makefile is meant to be a
description of the process, a.k.a. documentation.

## USAGE

(See **CAVEATS**.)

The way I run it is:

1. Run `make privs`.  This will accomplish all but the last step of
   running the Java code against the DB.

2. Manually edit the DB connection string in `hibernate.cfg.xml` to
   use the public IP of a node in the cluster created by `roachprod`.
   To see the public IPs associated with the cluster, do something
   like the following (replacing `rich` with your username):

        $ roachprod list -d | grep 'rich' | perl -lanE 'say $1 if /\b(35\..+)$/'
        35.237.243.228
        35.237.186.253
        35.237.80.0
        35.237.254.147

3. Run the Java code:

        $ gradle run
        ... many lines of Hibernate INFO logs ...
        INFO: HHH000397: Using ASTQueryTranslatorFactory
        1 1000
        2 250
        May 24, 2018 2:42:41 PM org.hibernate.engine.jdbc.connections.internal.DriverManagerConnectionProviderImpl stop

4. To clean everything up (including deleting local certs and
   destroying the remote cluster), run:

        $ make clean
