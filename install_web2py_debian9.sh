cwd=$(pwd)
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install unzip
sudo apt-get -y install nginx
sudo apt-get -y install virtualenv
sudo mkdir /var/www
cd /var/www
sudo wget http://www.web2py.com/examples/static/web2py_src.zip
sudo unzip web2py_src.zip
sudo rm web2py_src.zip
sudo chown -R www-data:www-data /var/www/web2py
cd web2py
sudo cp handlers/wsgihandler.py .
sudo cp $cwd/gunicorn.service /etc/systemd/system
sudo systemctl enable /etc/systemd/system/gunicorn.service
sudo cp $cwd/web2py.nginx_secure /etc/nginx/sites-available/web2py
sudo ln -s /etc/nginx/sites-available/web2py /etc/nginx/sites-enabled/web2py
sudo rm /etc/nginx/sites-enabled/default
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original
sudo cp $cwd/nginx.conf /etc/nginx/
sudo mkdir /etc/nginx/ssl
cd /etc/nginx/ssl
sudo openssl genrsa -out web2py.key 1024
sudo openssl req -batch -new -key web2py.key -out web2py.csr
sudo openssl x509 -req -days 1780 -in web2py.csr -signkey web2py.key -out web2py.crt
cd /var/www/web2py
echo -n Set web2py Admin Interface Password: 
read -s password
echo setting password...
sudo -u www-data python -c "from gluon.main import save_password;save_password('$password',9090)"
sudo apt-get -y install mysql-server
sudo mysql_secure_installation
printf "[Unit]\nDescription=Web2Py scheduler service\n#Enable to ensure that workers are started after mysql service\nAfter=mysql.service\n\n[Service]\nExecStart=/usr/bin/python /var/www/web2py/web2py.py -K welcome\nType=simple\nRestart=always\n[Install]\nWantedBy=multi-user.target" > $cwd/web2py-sched.service
sudo cp $cwd/web2py-sched.service /etc/systemd/system/web2py-sched.service
#install the service
sudo systemctl enable /etc/systemd/system/web2py-sched.service 
sudo -u www-data bash -c 'virtualenv /var/www/web2py;source /var/www/web2py/bin/activate;pip install gunicorn'
sudo service gunicorn restart
sudo service nginx restart
