sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install nginx
sudo apt-get -y install gunicorn
sudo mkdir /var/www
cd /var/www
sudo wget http://www.web2py.com/examples/static/web2py_src.zip
sudo unzip web2py_src.zip
sudo rm web2py_src.zip
cd web2py
sudo cp handlers/wsgihandler.py .
sudo chown -R www-data:www-data /var/www/web2py
sudo touch /etc/gunicorn.d/web2py
printf "CONFIG = {\n    # 'mode': 'wsgi',\n    'working_dir': '/var/www/web2py',\n    # 'python': '/usr/bin/python',\n    'args': (\n        '--user=www-data', '--group=www-data',\n        '--bind=127.0.0.1:9090',\n        '--workers=1',\n        '--timeout=600',\n        #'--worker-class=eventlet', # choose a worker class, here i'm using eventlet\n        'wsgihandler',\n    ),\n}" > ~/web2py.gunicorn
printf "upstream gunicorn {\n        #server unix:/tmp/gunicorn.sock fail_timeout=0;\n        # For a TCP configuration:\n        server 127.0.0.1:9090 fail_timeout=0;\n}\n \nserver {\n        listen 80 default;\n        client_max_body_size 4G;\n        server_name \$hostname;\n \n        keepalive_timeout 5;\n \n        location ~* /(\w+)/static/ {\n                root /var/www/web2py/applications/;\n        }\n \n        ## gunicorn\n        location / {\n                # checks for static file, if not found proxy to app\n                try_files \$uri @proxy_to_gunicorn;\n        }\n \n        location @proxy_to_gunicorn {\n                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n                proxy_set_header Host \$http_host;\n                proxy_redirect off;\n \n                proxy_pass   http://gunicorn;\n        }\n}\nserver {\n        listen 443 default_server ssl;\n        client_max_body_size 4G;\n        server_name \$hostname;\n \n        ssl_certificate /etc/nginx/ssl/web2py.crt;\n        ssl_certificate_key /etc/nginx/ssl/web2py.key;\n \n        location / {\n                # checks for static file, if not found proxy to app\n                try_files \$uri @proxy_to_gunicorn;\n        }\n \n        location @proxy_to_gunicorn {\n                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n                proxy_set_header X-Forwarded-Ssl on;\n                proxy_set_header Host \$http_host;\n                proxy_redirect off;\n \n                proxy_pass   http://gunicorn;\n        }\n}\n" > ~/web2py.nginx
sudo cp ~/web2py.gunicorn /etc/gunicorn.d/web2py
sudo cp ~/web2py.nginx /etc/nginx/sites-available/web2py
sudo ln -s /etc/nginx/sites-available/web2py /etc/nginx/sites-enabled/web2py
sudo rm /etc/nginx/sites-enabled/default
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original
sudo cp ~/nginx.conf /etc/nginx/
sudo mkdir /etc/nginx/ssl
cd /etc/nginx/ssl
sudo openssl genrsa -out web2py.key 1024
sudo openssl req -batch -new -key web2py.key -out web2py.csr
sudo openssl x509 -req -days 1780 -in web2py.csr -signkey web2py.key -out web2py.crt
cd /var/www/web2py
echo -n Set web2py Admin Interface Password: 
read -s password
sudo -u www-data python -c "from gluon.main import save_password;save_password('$password',9090)"
sudo service gunicorn restart
sudo service nginx restart
sudo apt-get -y install mysql-server
printf "[Unit]\nDescription=Web2Py scheduler service\n\n[Service]\nExecStart=/usr/bin/python /var/www-data/web2py/web2py.py -K welcome\nType=simple\n\n[Install]\nWantedBy=multi-user.target" > ~/web2py-sched.service
sudo cp ~/web2py-sched.service /etc/systemd/system/web2py-sched.service
#install the service
sudo systemctl enable /etc/systemd/system/web2py-sched.service 
