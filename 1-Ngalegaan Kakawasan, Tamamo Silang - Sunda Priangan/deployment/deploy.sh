sudo cp ~/asm-server/deployment/asm-server.service /etc/systemd/system/asm-server.service
sudo cp ~/asm-server/deployment/asm-nginx /etc/nginx/sites-available/asm-nginx
sudo systemctl enable asm-server.service
sudo systemctl start asm-server.service
sudo systemctl status asm-server.service
sudo ln -s /etc/nginx/sites-available/asm-nginx /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl status nginx
sudo certbot --nginx