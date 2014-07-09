#!/bin/bash

###
#
#  simple mail sender using sendmail
#  you need to install commands "sendmail" and "nkf"...
#
###

CMD_MAIL="/usr/sbin/sendmail"

###
#
# style of from, to, cc, bcc
# "hoge <hoge@hoge.hoge>, fuga <fuga@fuga.fuga>"
#
###
MAIL_FROM=""
MAIL_TO=""
MAIL_CC=""
MAIL_BCC=""
SUBJECT=""
BODY=""

# /tmp/hoge.pdf  etc... (only single file)
ATTACH=""

# Content-Transfer-Encoding
CTF="7bit"
ENC_BASE="$(echo $LANG | cut -d '.' -f 2)"
ENC_MAIL="iso-2022-jp"
ENC_NKF="-j"

#BOUNDARY="--$(uuidgen)" ## Generates Unique ID
BOUNDARY="--$(date +%Y%m%d%H%M%N)" ## Generates Unique ID
FILE_EMAIL="/tmp/email_$(date +'%Y%m%d_%H%M%S').out"

while getopts ":a:b:c:e:f:s:t:" opt; do
        case ${opt} in
        a)
                ATTACH=${OPTARG}
                ;;
        b)
                MAIL_BCC=${OPTARG}
                ;;
        c)
                MAIL_CC=${OPTARG}
                ;;
        e)
                ENC_MAIL="${OPTARG}"
                ENC_MAIL_LC="$(echo ${OPTARG} | tr '[:upper:]' '[:lower:]')"
                case ${ENC_MAIL_LC} in
                "iso-2022-jp")
                        ENC_NKF="-j"
                        ;;
                "euc-jp")
                        ENC_NKF="-e"
                        ;;
                "shift-jis")
                        ENC_NKF="-s"
                        ;;
                "utf-8")
                        ENC_NKF="-w"
                        ;;
                esac
#               if [ "${ENC_MAIL_LC}" = "iso-2022-jp" ]; then
#                       :
#               fi
                ;;
        f)
                MAIL_FROM=${OPTARG}
                ;;
        s)
                SUBJECT=${OPTARG}
                ;;
        t)
                MAIL_TO=${OPTARG}
                ;;
        esac
done

#echo ${ENC_BASE}
#echo ${ENC_MAIL}
#echo ${ENC_NKF}
#echo ${SUBJECT}

# other arguments
shift $((OPTIND - 1))
BODY="$1"

### iconv だと、㈱ などを変換できない
#BODYENC="$(echo -e "${BODY}" | iconv -c -f ${ENC_BASE} -t ${ENC_MAIL})"
SUBJECT_ENC="=?${ENC_MAIL}?B?$(echo ${SUBJECT} | nkf ${ENC_NKF} | base64 | tr -d '\n')?="
BODY_ENC="$(echo -e "${BODY}" | nkf ${ENC_NKF})"
ATTACH_ENC="=?${ENC_MAIL}?B?$(basename ${ATTACH} | nkf ${ENC_NKF} | base64 | tr -d '\n')?="

# image/jpeg;  etc... (includeing ";" is ok.)
MIME_ATTACH="$(file -i ${ATTACH} | cut -d ' ' -f2)"

### send email
(
# header
 echo "From: ${MAIL_FROM}"
if [ "${MAIL_TO}" != "" ]; then
 echo "To: ${MAIL_TO}"
fi
if [ "${MAIL_CC}" != "" ]; then
 echo "Cc: ${MAIL_CC}"
fi
if [ "${MAIL_BCC}" != "" ]; then
 echo "Bcc: ${MAIL_BCC}"
fi
 echo "Subject: ${SUBJECT_ENC}"
 echo "MIME-Version: 1.0"
 echo "Content-Type: multipart/mixed;"
 echo " boundary=\"${BOUNDARY}\""
 echo "Content-Transfer-Encoding: ${CTF}"
 echo ""
 echo "This is a multi-part message in MIME format."
 echo ""

# body
 echo "--${BOUNDARY}"
 echo "Content-Type: text/plain; charset=${ENC_MAIL}"
 echo "Content-Transfer-Encoding: ${CTF}"
 echo ""
 echo "${BODY_ENC}"
 echo ""

# attach file
 echo "--${BOUNDARY}"
 echo "Content-Type: ${MIME_ATTACH}"
 echo " name=${ATTACH_ENC}"
 echo "Content-Transfer-Encoding: base64"
 echo "Content-Disposition: attachment;"
 echo " filename=${ATTACH_ENC}"
 echo ""
 #uuencode -m $ATTACH $(basename $ATTACH)
 cat ${ATTACH} | base64
 echo ""
 echo "--${BOUNDARY}--"
) > ${FILE_EMAIL}

${CMD_MAIL} -t < ${FILE_EMAIL}
