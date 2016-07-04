FROM ubuntu:16.04
MAINTAINER Samuel Fernando Mesa Giraldo <samuelmesa@gmail.com> 
# Base: Yves Jacolin <yjacolin@free.fr>

ENV VERSION 2016-07-04
ENV TERM xterm
ENV APACHE_CONFDIR /etc/apache2
ENV APACHE_ENVVARS $APACHE_CONFDIR/envvars
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_PID_FILE $APACHE_RUN_DIR/apache2.pid
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV LANG C
ENV APACHE_PID_FILE /var/run/apache2/apache2.pid
ENV PGSERVICEFILE /gisdata/projects/pg_service.conf
ENV MAPCACHE_VERSION=1.4.0

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key 3FF5FFCAD71472C4 && \
    echo "deb     http://qgis.org/debian xenial main" > /etc/apt/sources.list.d/qgis.list

RUN apt-get update
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -qqy git cmake \
    software-properties-common g++ make build-essential \
    libaprutil1-dev libapr1-dev libpng12-dev libjpeg-dev \
    libcurl4-gnutls-dev libpcre3-dev libpixman-1-dev libgdal-dev \
    libgeos-dev libsqlite3-dev libdb-dev libtiff-dev \
    apache2-dev libfcgi-dev db-util \
    qgis-server libapache2-mod-fcgid \
    cgi-mapserver libmapserver-dev mapserver-bin python-mapscript

# Install Mapcache itself
RUN git clone https://github.com/mapserver/mapcache.git /usr/local/src/mapcache && \
    cd /usr/local/src/mapcache && git checkout ${MAPCACHE_VERSION}

# Compile Mapcache for Apache
RUN mkdir /usr/local/src/mapcache/build && \
    cd /usr/local/src/mapcache/build && \
    cmake ../ -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_VERBOSE_MAKEFILE=1 \
        -DWITH_PIXMAN=1 \
        -DWITH_SQLITE=1 \
        -DWITH_BERKELEY_DB=1 \
        -DWITH_TIFF=1 \
        -DWITH_TIFF_WRITE_SUPPORT=0 \
        -DWITH_GEOTIFF=0 \
        -DWITH_MAPSERVER=0 \
        -DWITH_PCRE=1 \
        -DWITH_APACHE=1 \
        -DWITH_VERSION_STRING=1 \
        -DWITH_CGI=1 \
        -DWITH_FCGI=1 \
        -DWITH_GEOS=1 \
        -DWITH_OGR=1 \
        -DWITH_MEMCACHE=1 \
        -DCMAKE_PREFIX_PATH="/etc/apache2" && \
    make && \
    make install

# Force buit libraries dependencies
RUN ldconfig    

RUN mkdir /mapcache
RUN mkdir /gisdata
RUN mkdir /gisdata/projects
RUN mkdir /gisdata/tiles
RUN chown -R www-data:www-data /gisdata/tiles && chmod -R 777 /gisdata/tiles
ADD mapcache.xml /mapcache/mapcache.xml
ADD gisserver.conf /etc/apache2/sites-available/gisserver.conf
ADD mapcache.load /etc/apache2/mods-available/mapcache.load
ADD apache2.sh /usr/local/bin/apache2.sh

RUN a2enmod mapcache
RUN a2dissite 000-default
RUN a2ensite gisserver
RUN a2enmod fcgid
RUN a2enmod cgid
RUN a2enmod rewrite

RUN apt-get purge -y software-properties-common build-essential cmake ; \
    apt-get purge -y libfcgi-dev liblz-dev libpng-dev libgdal-dev libgeos-dev \
    libpixman-1-dev libsqlite0-dev libcurl4-openssl-dev \
    libaprutil1-dev libapr1-dev libjpeg-dev libdpkg-dev \
    libdb5.3-dev libtiff5-dev libpcre3-dev ; \
    apt-get autoremove -y ; \
    apt-get clean ; \
    rm -rf /var/lib/apt/lists/partial/* /tmp/* /var/tmp/*

WORKDIR /mapcache
VOLUME ["/mapcache", "/gisdata/projects", "/gisdata/tiles"]

EXPOSE 80

CMD ["bash", "apache2.sh"]