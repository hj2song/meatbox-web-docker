#!/bin/sh

mkdir /home/DATA/www-deploy/meatbox-web2/src/main/webapp/web /home/DATA/www-deploy/meatbox-web2/src/main/webapp/m
chown www:www -R /home/DATA/www-deploy/meatbox-web2
ln -s /home/DATA/share/meatbox/naver/naver_shopping_sales_index_ep.tsv /home/DATA/www-deploy/meatbox-m2/src/main/webapp/naver_shopping_sales_index_ep.tsv
ln -s /home/DATA/share/meatbox/naver/naver_ep.tsv /home/DATA/www-deploy/meatbox-m2/src/main/webapp/naver_ep.tsv 
ln -s /home/DATA/share/meatbox/images /home/DATA/www-deploy/meatbox-m2/src/main/webapp/web/images
ln -s /home/DATA/share/meatbox/images /home/DATA/www-deploy/meatbox-m2/src/main/webapp/m/images
