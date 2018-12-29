if [ -f .passwdb ]; then
    PASSWDB=$(<.passwdb)
else
    PASSWDB="$(openssl rand -base64 12)"
    echo "$PASSWDB" >.passwdb
fi
DBNAME="CDSdb"
USERNAME="cdsuser"
MYSQLSERVER="localhost"
#echo "Please enter root user MySQL password!"
#read -s rootpasswd
echo .
echo "Please enter user remote @host ip:"
read hostip
sudo mysql -h ${MYSQLSERVER} -e "CREATE DATABASE ${DBNAME};"
sudo mysql -h ${MYSQLSERVER} -e "CREATE USER ${USERNAME}@'${hostip}' IDENTIFIED BY '${PASSWDB}';"
sudo mysql -h ${MYSQLSERVER} -e "GRANT ALL PRIVILEGES ON ${DBNAME}.* TO '${USERNAME}'@'${hostip}';"
sudo mysql -h ${MYSQLSERVER} -e "FLUSH PRIVILEGES;"
