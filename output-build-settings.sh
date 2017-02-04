#!/bin/sh

XCDANGER_PROJECT="${1}"

# swap file separator characters to keep files with spaces in paths from breaking to two items as find output
OIFS="$IFS"
IFS=$'\n'

XCDANGER_SCHEMES=`find "${XCDANGER_PROJECT}"/xcshareddata -name "*.xcscheme"`
XCDANGER_CONFIGURATIONS=`xcodebuild -project "${XCDANGER_PROJECT}" -list | ruby list-configurations.rb`

XCDANGER_OUTPUT_PATH="${XCDANGER_PROJECT}/../.xcdanger/"
mkdir -p "${XCDANGER_OUTPUT_PATH}"

for XCDANGER_SCHEME_PATH in ${XCDANGER_SCHEMES[@]}; do
    
    # replace spaces in name with escape-quoted space characters, so that basename doesn't break the to new lines either
    XCDANGER_SCHEME_NAME=`echo "${XCDANGER_SCHEME_PATH}" | sed s/' '/'\"\ \"'/g | xargs basename | sed s/'.xcscheme'//g`
    
    for XCDANGER_CONFIGURATION in ${XCDANGER_CONFIGURATIONS[@]}; do
        sh -c "xcodebuild -project \"${XCDANGER_PROJECT}\" -scheme \"${XCDANGER_SCHEME_NAME}\" -configuration \"${XCDANGER_CONFIGURATION}\" -showBuildSettings > \"${XCDANGER_OUTPUT_PATH}/${XCDANGER_SCHEME_NAME}.${XCDANGER_CONFIGURATION}\".settings.lock"
    done
done

# replace the old file separator character
IFS="$OIFS" 
