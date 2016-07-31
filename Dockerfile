FROM phusion/baseimage:0.9.16

ENV baseDir .

RUN apt-get update && \
	curl -sL https://deb.nodesource.com/setup | sudo bash - \
	apt-get install -y build-essential \
		wget nodejs unzip time imagemagick optipng strace nginx git \
		python zlib1g-dev libpcre3-dev aspell aspell-en aspell-de \
		aspell-de-alt aspell-fr && \
	apt-get clean

RUN wget -O /opt/qpdf-6.0.0.tar.gz https://s3.amazonaws.com/sharelatex-random-files/qpdf-6.0.0.tar.gz && tar xzf qpdf-6.0.0.tar.gz && rm /opt/qpdf-6.0.0.tar.gz
WORKDIR /opt/qpdf-6.0.0
RUN ./configure && make -j4 && make install && ldconfig

# Install TexLive
RUN wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz; \
	mkdir /install-tl-unx; \
	tar -xvf install-tl-unx.tar.gz -C /install-tl-unx --strip-components=1 && \
	echo "selected_scheme scheme-full" >> /install-tl-unx/texlive.profile; \
	/install-tl-unx/install-tl -profile /install-tl-unx/texlive.profile && \
	rm -r /install-tl-unx; \
	rm install-tl-unx.tar.gz

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/texlive/2016/bin/x86_64-linux/
RUN tlmgr install latexmk && \
	npm install -g grunt-cli


# Set up sharelatex user and home directory
RUN adduser --system --group --home /var/www/sharelatex --no-create-home sharelatex; \
	mkdir -p /var/lib/sharelatex; \
	chown www-data:www-data /var/lib/sharelatex; \
	mkdir -p /var/log/sharelatex; \
	chown www-data:www-data /var/log/sharelatex; \
	mkdir -p /var/lib/sharelatex/data/template_files; \
	chown www-data:www-data /var/lib/sharelatex/data/template_files;


# Install ShareLaTeX
RUN git clone https://github.com/sharelatex/sharelatex.git /var/www/sharelatex #random_change

ADD ${baseDir}/services.js /var/www/sharelatex/config/services.js
ADD ${baseDir}/package.json /var/www/package.json
ADD ${baseDir}/git-revision.js /var/www/git-revision.js
WORKDIR /var/www
RUN npm install
WORKDIR /var/www/sharelatex

RUN npm install; \
	grunt install;

WORKDIR /var/www
RUN node git-revision > revisions.txt
WORKDIR /var/www/sharelatex/web
# Minify js assets
RUN grunt compile:minify;
WORKDIR /var/www/sharelatex/clsi
RUN grunt compile:bin && \
	mkdir /etc/service/nginx

ADD ${baseDir}/runit/nginx.sh /etc/service/nginx/run

# Set up ShareLaTeX services to run automatically on boot
RUN mkdir /etc/service/chat-sharelatex; \
	mkdir /etc/service/clsi-sharelatex; \
	mkdir /etc/service/docstore-sharelatex; \
	mkdir /etc/service/document-updater-sharelatex; \
	mkdir /etc/service/filestore-sharelatex; \
	mkdir /etc/service/real-time-sharelatex; \
	mkdir /etc/service/spelling-sharelatex; \
	mkdir /etc/service/tags-sharelatex; \
	mkdir /etc/service/track-changes-sharelatex; \
	mkdir /etc/service/web-sharelatex; \
	mkdir /etc/sharelatex


ADD ${baseDir}/runit/chat-sharelatex.sh             /etc/service/chat-sharelatex/run
ADD ${baseDir}/runit/clsi-sharelatex.sh             /etc/service/clsi-sharelatex/run
ADD ${baseDir}/runit/docstore-sharelatex.sh         /etc/service/docstore-sharelatex/run
ADD ${baseDir}/runit/document-updater-sharelatex.sh /etc/service/document-updater-sharelatex/run
ADD ${baseDir}/runit/filestore-sharelatex.sh        /etc/service/filestore-sharelatex/run
ADD ${baseDir}/runit/real-time-sharelatex.sh        /etc/service/real-time-sharelatex/run
ADD ${baseDir}/runit/spelling-sharelatex.sh         /etc/service/spelling-sharelatex/run
ADD ${baseDir}/runit/tags-sharelatex.sh             /etc/service/tags-sharelatex/run
ADD ${baseDir}/runit/track-changes-sharelatex.sh    /etc/service/track-changes-sharelatex/run
ADD ${baseDir}/runit/web-sharelatex.sh              /etc/service/web-sharelatex/run

RUN rm /etc/nginx/sites-enabled/default
ADD ${baseDir}/nginx/nginx.conf /etc/nginx/nginx.conf
ADD ${baseDir}/nginx/sharelatex.conf /etc/nginx/sites-enabled/sharelatex.conf

# phusion/baseimage init script
ADD ${baseDir}/init_scripts/00_regen_sharelatex_secrets.sh  /etc/my_init.d/00_regen_sharelatex_secrets.sh
ADD ${baseDir}/init_scripts/00_make_sharelatex_data_dirs.sh /etc/my_init.d/00_make_sharelatex_data_dirs.sh
ADD ${baseDir}/init_scripts/00_set_docker_host_ipaddress.sh /etc/my_init.d/00_set_docker_host_ipaddress.sh
ADD ${baseDir}/init_scripts/99_migrate.sh /etc/my_init.d/99_migrate.sh

# Install ShareLaTeX settings file
ADD ${baseDir}/settings.coffee /etc/sharelatex/settings.coffee
ENV SHARELATEX_CONFIG /etc/sharelatex/settings.coffee


EXPOSE 80
VOLUME /var/lib/sharelatex
WORKDIR /

ENTRYPOINT ["/sbin/my_init"]

