#!/bin/sh

link.sh

exitHandler() {
    echo "Server will be shutdown" 1>&2
    ${CATALINA_HOME}/bin/catalina.sh stop
}

trap `exitHandler` EXIT

catalina.sh run