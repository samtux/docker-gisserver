# Ubuntu GIS Server

[![Docker Pulls](https://img.shields.io/docker/pulls/yjacolin/mapcache.svg)](https://hub.docker.com/r/samtux/gisserver/)

[![Travis](https://travis-ci.org/yjacolin/docker-mapcache.svg)](https://travis-ci.org/samtux/docker-gisserver)

GIS Server in Ubuntu Xenial with Mpserver, Mapcache and QGIS Server.

- Mapserver version 7.0.4
- Mapcache version 1.4.1
- QGIS Server v2.18.4

## Install
```
$ git clone
$ docker build -t samtux/gisserver .
```

## Run

```
$ docker run -d -p 8281:80 -v "gisdata":/gisdata -v config.xml:/mapcache/config.xml --name gisserver samtux/gisserver
```
