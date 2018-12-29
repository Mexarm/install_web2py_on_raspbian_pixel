if [ -f .mysql_admin_passwd ]; then
    PASSWDB=$(<.mysql_admin_passwd)
else
    echo "password not found!"
fi
mysql -uadmin -p$PASSWDB
