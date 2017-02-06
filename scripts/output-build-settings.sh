#!/bin/sh

# path to the .xcodeproj
XCDANGER_PROJECT="${1}"

# swap file separator characters to keep files with spaces in paths from breaking to two items as find output
OIFS="$IFS"
IFS=$'\n'

XCDANGER_SCHEMES=`find "${XCDANGER_PROJECT}"/xcshareddata -name "*.xcscheme"`
XCDANGER_CONFIGURATIONS=`xcodebuild -project "${XCDANGER_PROJECT}" -list | ruby scripts/list-configurations.rb`

XCDANGER_OUTPUT_PATH="${XCDANGER_PROJECT}/../.xcdanger/"
mkdir -p "${XCDANGER_OUTPUT_PATH}"

function unexpandSetting {
    XCDANGER_SETTING_NAME="${1}"
    XCDANGER_OUTPUT_FILE="${2}"
    
    # awk grabs the line containing the setting definition
    # cut discards the leading whitespace, THE_BUILD_SETTING_NAME and the '=', leaving just the value
    XCDANGER_COMMAND="awk '{if (\$1 == \"${XCDANGER_SETTING_NAME}\") print \$0;}' \"${XCDANGER_OUTPUT_FILE}\" | cut -d' ' -f7-"
    # echo "${XCDANGER_COMMAND}"
    XCDANGER_VALUE=`eval "${XCDANGER_COMMAND}"`
    
    if [[ -n "${XCDANGER_VALUE}" ]]; then
        XCDANGER_COMMAND="sed \"s%${XCDANGER_VALUE}%${XCDANGER_SETTING_NAME}%g\" \"${XCDANGER_OUTPUT_FILE}\" > \"${XCDANGER_OUTPUT_FILE}\".new"
        # echo "${XCDANGER_COMMAND}"
        eval "${XCDANGER_COMMAND}"
        
        rm "${XCDANGER_OUTPUT_FILE}"
        mv "${XCDANGER_OUTPUT_FILE}.new" "${XCDANGER_OUTPUT_FILE}"
    else
        echo "!!! no value for ${XCDANGER_SETTING_NAME}"
    fi
    
}
    
for XCDANGER_CONFIGURATION in ${XCDANGER_CONFIGURATIONS[@]}; do
    for XCDANGER_SCHEME_PATH in ${XCDANGER_SCHEMES[@]}; do
    
        # get the scheme name from the .xcscheme path. 
        # replace spaces in name with escape-quoted space characters, so that basename doesn't break them to new lines either
        XCDANGER_SCHEME_NAME=`echo "${XCDANGER_SCHEME_PATH}" | sed s/' '/'\"\ \"'/g | xargs basename | sed s/'.xcscheme'//g`
    
        # file we'll write the settings to: /path/to/.../.xcdanger/<configuration>/<scheme-name>.build-settings.lock
        XCDANGER_OUTPUT_DIR="${XCDANGER_OUTPUT_PATH}/${XCDANGER_CONFIGURATION}"
        mkdir -p "${XCDANGER_OUTPUT_DIR}"
        XCDANGER_OUTPUT_FILE="${XCDANGER_OUTPUT_DIR}/${XCDANGER_SCHEME_NAME}.build-settings.lock"
        
        # output the xcode build settings for the scheme/configuration
        xcodebuild \
            -project "${XCDANGER_PROJECT}" \
            -scheme "${XCDANGER_SCHEME_NAME}" \
            -configuration "${XCDANGER_CONFIGURATION}" \
            -showBuildSettings \
            > "${XCDANGER_OUTPUT_FILE}"

        # replace any user-specific paths with the variable name they were derived from
        XCDANGER_UNEXPANDED_SETTINGS=`cat lib/settings-to-unexpand`
        for XCDANGER_UNEXPANDED_SETTING in ${XCDANGER_UNEXPANDED_SETTINGS[@]}; do
            unexpandSetting "${XCDANGER_UNEXPANDED_SETTING}" "${XCDANGER_OUTPUT_FILE}"
        done

    done
done

# replace the old file separator character
IFS="$OIFS" 
