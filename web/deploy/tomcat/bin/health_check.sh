#! /bin/sh

PORT=${1}

if [ -z "$PORT" ]; then
    echo "Port not provided"
    exit 1
fi

CURL="http://localhost:${PORT}/health"

echo "Start Web Check"
loop=0
http_status="FAIL"
echo "web service check start"

while [ ${loop} -le 30 ]; do
    result=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 ${CURL})
    if [ "$result" == "200" ]; then
        http_status="TRUE"
        echo ${CURL}" - web check success"
        break
    else
        echo "web check trying ... "${loop}"/30"
    fi
    loop=$((loop+1))
    sleep 1
done

if [ "FAIL" == "${http_status}" ]; then
    echo "fail - "${CURL}" http_code : "${result}
    echo "End Web Check\n"
    exit 1
fi
echo "web service check end"