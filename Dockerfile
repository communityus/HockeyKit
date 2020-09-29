FROM trafex/alpine-nginx-php7:latest
MAINTAINER jhughes2112 "jhughes+hockeykit@reachablegames.com"

EXPOSE 8000

USER root

ADD server/php /var/www/html/
ADD hockeykit.conf /etc/nginx/conf.d/hockeykit.conf
ADD startup.sh /startup.sh
RUN chmod a+rx /startup.sh && \
	chown -R nobody:nobody /var/www/html && \
	rm /var/www/html/test.html && \
	rm /var/www/html/index.php

USER nobody
ENTRYPOINT [ "/startup.sh" ]
# ENTRYPOINT [ "/bin/sh" ]
