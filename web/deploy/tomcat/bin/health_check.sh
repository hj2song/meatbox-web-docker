#! /bin/sh

PORT=${1}

if [ -z "$PORT" ]; then
    echo "Port not provided"
    exit 1
fi

CURL="http://localhost:${PORT}/health"

result=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 ${CURL})
if [ "$result" == "200" ]; then
    http_status="TRUE"
    echo ${CURL}" - web check success"
    exit 0
else
    echo "fail - "${CURL}" http_code : "${result}
fi
if [ "FAIL" == "${http_status}" ]; then
    echo "fail - "${CURL}" http_code : "${result}
    echo "End Web Check\n"
    exit 1
fi
echo "web service check end"