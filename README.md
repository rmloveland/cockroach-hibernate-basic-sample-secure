# CockroachDB Hibernate Basic Sample - Secure (tm)

**NOTE**: This doesn't actually work yet.  Right now it's trying to
capture a description of tasks in the Makefile.  There is still work
to do here.

**NOTE**: This is not an official repo of Cockroach Labs.  I work
there, but this is me trying to figure some things out before they
make their way into the actual docs.  For officially supported
content, [read the docs][docs].

This repo will at some point have an example of how to connect to a
secure CockroachDB cluster from Java using Hibernate.  For now, you
can probably ignore it because everything is wrong.

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

As noted above, this doesn't quite work yet.  And it definitely isn't
ready for someone else to use.  For example, it uses hardcoded
variables such as my username.  Right now the Makefile is meant to be
a description of the process, a.k.a. documentation.

## USAGE

(See **CAVEATS**.)

The way I run it is:

1. Run `make privs`.  This will accomplish all but the last step of
   running the Java code against the DB.  (Unless there is an i/o
   timeout with GCE when copying over the binaries, which has
   happened, in which case everything grinds to a halt.)

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

## OPEN QUESTIONS

In no particular order.

### JDBC and Certs and Passwords

Right now it appears that [the JDBC driver requires a password even when certs are specified in the connection string][jdbc_issue].  I am also experiencing this behavior.  According to that issue, apparently the JDBC Postgres driver ignores client certificate errors and proceeds anyway.  Perhaps this is what is happening to me?  I specified an SSL debug flag to the JVM in the `gradle.properties` file that (AFAICT) is supposed to cause verbose SSL handshake output or something, but it seems to be having no effect.

I ended up creating a secure cluster, using the certs in the DB connection string, and having to specify a username and password anyway in order to get the example code to work over a secure connection.  At least according to [the CREATE USER doc][create_user], you should be able to do this without a password.

Bit of trivia perhaps, but I could not get the `postgres://maxroach:foo@1.2.3.4:26257/bank?XXX` syntax for username and password to work with JDBC.  I had to specify the username and password in the Hibernate XML config instead (they also work in the connection string URL, but we discourage that [in our docs][connection_url]).

Anyway, I absolutely could not connect with just a username and a cert.  Everything I tried led to the error below - it appears JDBC **REALLY** wants you to use a password (?).  But maybe there is something really obvious I'm missing that will be clear from a look at the Makefile.  I don't have enough context about how all of this works to know.

    > Task :run FAILED
    May 23, 2018 4:00:26 PM org.hibernate.Version logVersion
    INFO: HHH000412: Hibernate Core {5.2.4.Final}
    May 23, 2018 4:00:26 PM org.hibernate.cfg.Environment <clinit>
    INFO: HHH000206: hibernate.properties not found
    May 23, 2018 4:00:26 PM org.hibernate.cfg.Environment buildBytecodeProvider
    INFO: HHH000021: Bytecode provider name : javassist
    May 23, 2018 4:00:26 PM org.hibernate.annotations.common.reflection.java.JavaReflectionManager <clinit>
    INFO: HCANN000001: Hibernate Commons Annotations {5.0.1.Final}
    May 23, 2018 4:00:26 PM org.hibernate.engine.jdbc.connections.internal.DriverManagerConnectionProviderImpl configure
    WARN: HHH10001002: Using Hibernate built-in connection pool (not for production use!)
    May 23, 2018 4:00:26 PM org.hibernate.engine.jdbc.connections.internal.DriverManagerConnectionProviderImpl buildCreator
    INFO: HHH10001005: using driver [org.postgresql.Driver] at URL [jdbc:postgresql://35.227.71.234:26257/bank?ssl=true&sslcert=/tmp/certs/node.der&sslfactory=org.postgresql.ssl.NonValidatingFactory&verifyServerCertificate=false]
    May 23, 2018 4:00:26 PM org.hibernate.engine.jdbc.connections.internal.DriverManagerConnectionProviderImpl buildCreator
    INFO: HHH10001001: Connection properties: {user=maxroach}
    May 23, 2018 4:00:26 PM org.hibernate.engine.jdbc.connections.internal.DriverManagerConnectionProviderImpl buildCreator
    INFO: HHH10001003: Autocommit mode: false
    May 23, 2018 4:00:26 PM org.hibernate.engine.jdbc.connections.internal.PooledConnections <init>
    INFO: HHH000115: Hibernate connection pool size: 20 (min=1)
    Exception in thread "main" java.lang.ExceptionInInitializerError
    Caused by: org.hibernate.service.spi.ServiceException: Unable to create requested service [org.hibernate.engine.jdbc.env.spi.JdbcEnvironment]
        at org.hibernate.service.internal.AbstractServiceRegistryImpl.createService(AbstractServiceRegistryImpl.java:267)
        at org.hibernate.service.internal.AbstractServiceRegistryImpl.initializeService(AbstractServiceRegistryImpl.java:231)
        at org.hibernate.service.internal.AbstractServiceRegistryImpl.getService(AbstractServiceRegistryImpl.java:210)
        at org.hibernate.engine.jdbc.internal.JdbcServicesImpl.configure(JdbcServicesImpl.java:51)
        at org.hibernate.boot.registry.internal.StandardServiceRegistryImpl.configureService(StandardServiceRegistryImpl.java:94)
        at org.hibernate.service.internal.AbstractServiceRegistryImpl.initializeService(AbstractServiceRegistryImpl.java:240)
        at org.hibernate.service.internal.AbstractServiceRegistryImpl.getService(AbstractServiceRegistryImpl.java:210)
        at org.hibernate.boot.model.process.spi.MetadataBuildingProcess.handleTypes(MetadataBuildingProcess.java:352)
        at org.hibernate.boot.model.process.spi.MetadataBuildingProcess.complete(MetadataBuildingProcess.java:111)
        at org.hibernate.boot.model.process.spi.MetadataBuildingProcess.build(MetadataBuildingProcess.java:83)
        at org.hibernate.boot.internal.MetadataBuilderImpl.build(MetadataBuilderImpl.java:418)
        at org.hibernate.boot.internal.MetadataBuilderImpl.build(MetadataBuilderImpl.java:87)
        at org.hibernate.cfg.Configuration.buildSessionFactory(Configuration.java:691)
        at org.hibernate.cfg.Configuration.buildSessionFactory(Configuration.java:726)
        at com.cockroachlabs.Sample.<clinit>(Sample.java:20)
    Caused by: org.hibernate.exception.JDBCConnectionException: Error calling Driver#connect
        at org.hibernate.exception.internal.SQLStateConversionDelegate.convert(SQLStateConversionDelegate.java:115)
        at org.hibernate.engine.jdbc.connections.internal.BasicConnectionCreator$1$1.convert(BasicConnectionCreator.java:101)
        at org.hibernate.engine.jdbc.connections.internal.BasicConnectionCreator.convertSqlException(BasicConnectionCreator.java:123)
        at org.hibernate.engine.jdbc.connections.internal.DriverConnectionCreator.makeConnection(DriverConnectionCreator.java:41)
        at org.hibernate.engine.jdbc.connections.internal.BasicConnectionCreator.createConnection(BasicConnectionCreator.java:58)
        at org.hibernate.engine.jdbc.connections.internal.PooledConnections.addConnections(PooledConnections.java:123)
        at org.hibernate.engine.jdbc.connections.internal.PooledConnections.<init>(PooledConnections.java:42)
        at org.hibernate.engine.jdbc.connections.internal.PooledConnections.<init>(PooledConnections.java:20)
        at org.hibernate.engine.jdbc.connections.internal.PooledConnections$Builder.build(PooledConnections.java:161)
        at org.hibernate.engine.jdbc.connections.internal.DriverManagerConnectionProviderImpl.buildPool(DriverManagerConnectionProviderImpl.java:109)
        at org.hibernate.engine.jdbc.connections.internal.DriverManagerConnectionProviderImpl.configure(DriverManagerConnectionProviderImpl.java:72)
        at org.hibernate.boot.registry.internal.StandardServiceRegistryImpl.configureService(StandardServiceRegistryImpl.java:94)
        at org.hibernate.service.internal.AbstractServiceRegistryImpl.initializeService(AbstractServiceRegistryImpl.java:240)
        at org.hibernate.service.internal.AbstractServiceRegistryImpl.getService(AbstractServiceRegistryImpl.java:210)
        at org.hibernate.engine.jdbc.env.internal.JdbcEnvironmentInitiator.buildJdbcConnectionAccess(JdbcEnvironmentInitiator.java:145)
        at org.hibernate.engine.jdbc.env.internal.JdbcEnvironmentInitiator.initiateService(JdbcEnvironmentInitiator.java:66)
        at org.hibernate.engine.jdbc.env.internal.JdbcEnvironmentInitiator.initiateService(JdbcEnvironmentInitiator.java:35)
        at org.hibernate.boot.registry.internal.StandardServiceRegistryImpl.initiateService(StandardServiceRegistryImpl.java:88)
        at org.hibernate.service.internal.AbstractServiceRegistryImpl.createService(AbstractServiceRegistryImpl.java:257)
        ... 14 more
    Caused by: org.postgresql.util.PSQLException: The server requested password-based authentication, but no password was provided.
        at org.postgresql.core.v3.ConnectionFactoryImpl.doAuthentication(ConnectionFactoryImpl.java:514)
        at org.postgresql.core.v3.ConnectionFactoryImpl.openConnectionImpl(ConnectionFactoryImpl.java:208)
        at org.postgresql.core.ConnectionFactory.openConnection(ConnectionFactory.java:67)
        at org.postgresql.jdbc.PgConnection.<init>(PgConnection.java:216)
        at org.postgresql.Driver.makeConnection(Driver.java:406)
        at org.postgresql.Driver.connect(Driver.java:274)
        at org.hibernate.engine.jdbc.connections.internal.DriverConnectionCreator.makeConnection(DriverConnectionCreator.java:38)
        ... 29 more

    FAILURE: Build failed with an exception.

[docs]: https://www.cockroachlabs.com/docs
[jdbc_issue]: https://github.com/cockroachdb/cockroach/issues/24487
[connection_url]: https://www.cockroachlabs.com/docs/stable/connection-parameters.html#connect-using-a-url
[create_user]: https://www.cockroachlabs.com/docs/stable/create-user.html#user-authentication
