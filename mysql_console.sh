if [ -f .passwdb ]; then
    PASSWDB=$(<.passwdb)
else
    echo "password not found!"
fi
mysql -uadmin -p$PASSWDB
