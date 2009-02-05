#!@SH_BIN@

set -x
set -e
SMSD_PID=0

SERVICE="$1"

echo "NOTICE: This test is quite tricky about timing, if you run it on really slow platform, it might fail."
echo "NOTICE: Testing service $SERVICE"

cleanup() {
    if [ $SMSD_PID -ne 0 ] ; then
        kill $SMSD_PID
        sleep 1
    fi
}

trap cleanup INT QUIT EXIT

cd @CMAKE_CURRENT_BINARY_DIR@

rm -rf smsd-test-$SERVICE
mkdir smsd-test-$SERVICE
cd smsd-test-$SERVICE

# Dummy backend storage
mkdir gammu-dummy
# Create config file
cat > .smsdrc <<EOT
[gammu]
model = dummy
connection = none
port = @CMAKE_CURRENT_BINARY_DIR@/smsd-test-$SERVICE/gammu-dummy
gammuloc = /dev/null
loglevel = textall

[smsd]
commtimeout = 1
debuglevel = 255
logfile = stderr
runonreceive = @CMAKE_CURRENT_BINARY_DIR@/smsd-test-$SERVICE/received.sh
EOT

# Create database and add driver specific configuration
case $SERVICE in
    dbi-sqlite3)
        @SQLITE_BIN@ smsd.db < @CMAKE_CURRENT_SOURCE_DIR@/../docs/sql/sqlite.sql
        cat >> .smsdrc <<EOT
service = dbi
driver = sqlite3
database = smsd.db
dbdir = @CMAKE_CURRENT_BINARY_DIR@/smsd-test-$SERVICE/
EOT
        ;;
    dbi-pgsql)
        echo "DROP TABLE IF EXISTS daemons, gammu, inbox, outbox, outbox_multipart, pbk, pbk_groups, phones, sentitems;" | PGPASSWORD=@PSQL_PASSWORD@ @PSQL_BIN@ -U @PSQL_USER@ @PSQL_DATABASE@
        PGPASSWORD=@PSQL_PASSWORD@ @PSQL_BIN@ -U @PSQL_USER@ @PSQL_DATABASE@ < @CMAKE_CURRENT_SOURCE_DIR@/../docs/sql/pgsql.sql
        cat >> .smsdrc <<EOT
service = dbi
driver = pgsql
pc = @PSQL_HOST@
database = @PSQL_DATABASE@
user = @PSQL_USER@
password = @PSQL_PASSWORD@
EOT
        ;;
    pgsql)
        echo "DROP TABLE IF EXISTS daemons, gammu, inbox, outbox, outbox_multipart, pbk, pbk_groups, phones, sentitems;" | PGPASSWORD=@PSQL_PASSWORD@ @PSQL_BIN@ -U @PSQL_USER@ @PSQL_DATABASE@
        PGPASSWORD=@PSQL_PASSWORD@ @PSQL_BIN@ -U @PSQL_USER@ @PSQL_DATABASE@ < @CMAKE_CURRENT_SOURCE_DIR@/../docs/sql/pgsql.sql
        cat >> .smsdrc <<EOT
service = pgsql
pc = @PSQL_HOST@
database = @PSQL_DATABASE@
user = @PSQL_USER@
password = @PSQL_PASSWORD@
EOT
        ;;
    dbi-mysql)
        echo "DROP TABLE IF EXISTS  daemons, gammu, inbox, outbox, outbox_multipart, pbk, pbk_groups, phones, sentitems;" | @MYSQL_BIN@ -u@MYSQL_USER@ -p@MYSQL_PASSWORD@ @MYSQL_DATABASE@
        @MYSQL_BIN@ -u@MYSQL_USER@ -p@MYSQL_PASSWORD@ @MYSQL_DATABASE@ < @CMAKE_CURRENT_SOURCE_DIR@/../docs/sql/mysql.sql
        cat >> .smsdrc <<EOT
service = dbi
driver = mysql
pc = @MYSQL_HOST@
database = @MYSQL_DATABASE@
user = @MYSQL_USER@
password = @MYSQL_PASSWORD@
EOT
        ;;
    mysql)
        echo "DROP TABLE IF EXISTS  daemons, gammu, inbox, outbox, outbox_multipart, pbk, pbk_groups, phones, sentitems;" | @MYSQL_BIN@ -u@MYSQL_USER@ -p@MYSQL_PASSWORD@ @MYSQL_DATABASE@
        @MYSQL_BIN@ -u@MYSQL_USER@ -p@MYSQL_PASSWORD@ @MYSQL_DATABASE@ < @CMAKE_CURRENT_SOURCE_DIR@/../docs/sql/mysql.sql
        cat >> .smsdrc <<EOT
service = mysql
pc = @MYSQL_HOST@
database = @MYSQL_DATABASE@
user = @MYSQL_USER@
password = @MYSQL_PASSWORD@
EOT
        ;;
esac

cat > @CMAKE_CURRENT_BINARY_DIR@/smsd-test-$SERVICE/received.sh << EOT
#!@SH_BIN@
echo "\$@" >> @CMAKE_CURRENT_BINARY_DIR@/smsd-test-$SERVICE/received.log
EOT
chmod +x @CMAKE_CURRENT_BINARY_DIR@/smsd-test-$SERVICE/received.sh

CONFIG_PATH="@CMAKE_CURRENT_BINARY_DIR@/smsd-test-$SERVICE/.smsdrc"
DUMMY_PATH="@CMAKE_CURRENT_BINARY_DIR@/smsd-test-$SERVICE/gammu-dummy"

mkdir -p $sms $DUMMY_PATH/sms/1
mkdir -p $sms $DUMMY_PATH/sms/2
mkdir -p $sms $DUMMY_PATH/sms/3
mkdir -p $sms $DUMMY_PATH/sms/4
mkdir -p $sms $DUMMY_PATH/sms/5

@CMAKE_CURRENT_BINARY_DIR@/gammu-smsd -c "$CONFIG_PATH" &
SMSD_PID=$!

sleep 3

for sms in 62 68 74 ; do
    cp @CMAKE_CURRENT_SOURCE_DIR@/../tests/at-sms-encode/$sms.backup $DUMMY_PATH/sms/1/$sms
done

sleep 25

# It would be good it this worked:
#@CMAKE_CURRENT_BINARY_DIR@/gammu-smsd-inject -c "$CONFIG_PATH" TEXT 123465 -text "Lorem ipsum." &
#@CMAKE_CURRENT_BINARY_DIR@/gammu-smsd-inject -c "$CONFIG_PATH" TEXT 123465 -text "Lorem ipsum." &
#@CMAKE_CURRENT_BINARY_DIR@/gammu-smsd-inject -c "$CONFIG_PATH" TEXT 123465 -text "Lorem ipsum." &
@CMAKE_CURRENT_BINARY_DIR@/gammu-smsd-inject -c "$CONFIG_PATH" TEXT 123465 -text "Lorem ipsum."

for sms in 10 16 26 ; do
    cp @CMAKE_CURRENT_SOURCE_DIR@/../tests/at-sms-encode/$sms.backup $DUMMY_PATH/sms/3/$sms
done

sleep 25

@CMAKE_CURRENT_BINARY_DIR@/gammu-smsd-monitor -C -c "$CONFIG_PATH" -l 1 -d 0

if [ `wc -l < @CMAKE_CURRENT_BINARY_DIR@/smsd-test-$SERVICE/received.log` -ne 6 ] ; then
    echo "Wrong number of messages received!"
    exit 1
fi