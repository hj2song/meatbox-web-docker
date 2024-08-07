#!/bin/sh

link.sh


exitHandler() {
    echo "Server will be shutdown" 1>&2
    kill -TERM $(ps -ef | grep java | grep -v grep | awk '{print $1}')
}

trap `exitHandler` EXIT

catalina.sh run