#!/bin/bash

###
# usage
# ./get_sid.sh -h host -p port context user password
###

HOST=localhost
PORT=8080

while getopts :h:p: OPT
do
    case ${OPT} in
    h)
        HOST=${OPTARG}
        ;;
    p)
        PORT=${OPTARG}
        ;;
    esac
done

shift $((OPTIND - 1))

CONTEXT=$1
USER=$2
PASSWORD=$3

#echo ${HOST}
#echo ${PORT}
#echo ${CONTEXT}
#echo ${USER}
#echo ${PASSWORD}

BASIC_AUTH=$(echo -n "${USER}:${PASSWORD}" | base64)

URL_MANAGER="http://${HOST}:${PORT}/manager/html"
HEADER_AUTH="Authorization:Basic ${BASIC_AUTH}"

TOKEN="$(curl -s "${URL_MANAGER}" -H "${HEADER_AUTH}" | grep "sessions.*path=/${CONTEXT}")"

#echo ${TOKEN}

JSESSIONID=$(echo "${TOKEN}" | sed 's/.*jsessionid=\(.*\)?path.*/\1/')
CSRF_NONCE=$(echo "${TOKEN}" | sed 's/.*CSRF_NONCE=\(.*\)".*/\1/')

echo "JSESSIONID=${JSESSIONID}"
echo "CSRF_NONCE=${CSRF_NONCE}"

URL="${URL_MANAGER}/sessions?path=/${CONTEXT}&org.apache.catalina.filters.CSRF_NONCE=${CSRF_NONCE}"
HEADER_COOKIE="Cookie: JSESSIONID=${JSESSIONID}"

# curl -vs だと、ヘッダ比較結果も出力された
curl -s "${URL}" -H "${HEADER_AUTH}" -H "${HEADER_COOKIE}" | grep sessionIds | sed -e 's/^.*value="\(.*\)".*\/>.*$/\1/' > sidlist
