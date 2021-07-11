# Check user is root or not 

if [[ "${UID}" -ne 0 ]]
then
	echo "please run with sudo or as root."
	exit 1
fi


## Production Database Settings from which we will dump Database

source_db_host="database-host-endpoint"
source_db_user="username"
source_db_password="password"
source_dbname="db"

# Directory settings
directory="/var/mysqldump"

## Dumping DB

mysqldump -v --databases ${source_dbname} --single-transaction --host=${source_db_host} --user=${source_db_user} --password='devsdb&2019' --port=3306 > ${directory}/qorum_clone.sql

### Check if dumping was successfull or not
if [[ "${?}" -ne 0 ]]
then 
	echo "Production DB dumping was failed"
	exit 1
fi


### Renaming database name and dump file

dbfile="/var/mysqldump/qorum_clone.sql";
dbname="qorum";
dbnewname="qorum_dummy_production";
dbnewfile="/var/mysqldump/${dbnewname}.sql";
cat $dbfile | sed "/^CREATE DATABASE/ s=$dbname=$dbnewname=" | sed "/^CREATE TABLE/ s=$dbname=$dbnewname=" | sed "/^USE / s=$dbname=$dbnewname=" | sed "/^-- / s=$dbname=$dbnewname=" > $dbnewfile

### Check if renaming was successfull or not
if [[ "${?}" -ne 0 ]]
then
        echo "dump file renaming was failed"
        exit 1
fi

### Delete Old dataabse after renaming it

sudo rm -rf /var/mysqldump/qorum_clone.sql

if [[ "${?}" -ne 0 ]]
then
        echo "Deleting old sql file renaming was failed"
        exit 1

fi

## Dummy Database Settings where we will clone Production DB

destination_db_host="devs-db.cl0j9h0z9kwc.ap-southeast-1.rds.amazonaws.com"
destination_db_user="devs"
destination_db_password="devsdb&2019"
destination_dbname="qorum_dummy_production"

# Directory settings
#directory="/var/mysqldump"

## Restoring to dummy Database

mysql -v  --host=${destination_db_host} --database=${destination_dbname}  --user=${destination_db_user} --password='devsdb&2019' --port=3306 <  ${directory}/qorum_dummy_production.sql

### Check if restoring was successfull or not
if [[ "${?}" -ne 0 ]]
then
        echo "Dummy DB restoring was failed"
        exit 1
fi

## Delete dummy_production dump file


sudo rm -rf /var/mysqldump/qorum_dummy_production.sql

if [[ "${?}" -ne 0 ]]
then
        echo "Deleting dummy production sql file renaming was failed"
        exit 1

fi

### Final print 
echo "Qorum Database cloning is successful"
