#!/bin/bash

### get days of month
function getDaysOfMonth() {
        local YEAR=$1
        local MONTH=$2
        local DAYS=$(date -d "${YEAR}/${MONTH}/1 + 1 month - 1 day" +"%d")
        echo ${DAYS}
}
