#!/bin/sh

XCDANGER_PROJECT="${1}"

# swap file separator characters to keep files with spaces in paths from breaking to two items as find output
OIFS="$IFS"
IFS=$'\n'

XCDANGER_SCHEMES=`find "${XCDANGER_PROJECT}"/xcshareddata -name "*.xcscheme"`

XCDANGER_OUTPUT_PATH="${XCDANGER_PROJECT}/../.xcdanger/"
mkdir "${XCDANGER_OUTPUT_PATH}"

for XCDANGER_SCHEME_PATH in ${XCDANGER_SCHEMES[@]}; do
    
    # replace spaces in name with escape-quoted space characters, so that basename doesn't break the to new lines either
    XCDANGER_SCHEME_NAME=`echo "${XCDANGER_SCHEME_PATH}" | sed s/' '/'\"\ \"'/g | xargs basename | sed s/'.xcscheme'//g`
    
    sh -c "xcodebuild -project \"${XCDANGER_PROJECT}\" -scheme \"${XCDANGER_SCHEME_NAME}\" -showBuildSettings > \"${XCDANGER_OUTPUT_PATH}/${XCDANGER_SCHEME_NAME}\".settings.lock"
done

# replace the old file separator character
IFS="$OIFS" 
