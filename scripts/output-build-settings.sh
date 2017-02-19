#!/bin/sh

#set -x

# failure modes
XCDANGER_EXIT_NO_PATH_PROVIDED=1
XCDANGER_EXIT_INVALID_XCODEPROJ_PATH=2
XCDANGER_EXIT_BUILD_SETTINGS_CHANGED=3

# path to the .xcodeproj from the command line
XCDANGER_PROJECT="${1}"

# make sure we got a path to the .xcodeproj
if [[ -z "${XCDANGER_PROJECT}" ]]; then
	echo "You must provide a path to your .xcodeproj file as an argument to xcdanger."
	exit $XCDANGER_EXIT_NO_PATH_PROVIDED
fi

# if no xcode project file exists at $XCDANGER_PROJECT, stop. (-d checks if it's a directory)
if [[ ! -d "${XCDANGER_PROJECT}" ]]; then
	echo "${XCDANGER_PROJECT} is not a valid Xcode project. Make sure you have the correct path."
	exit $XCDANGER_EXIT_INVALID_XCODEPROJ_PATH
fi

# swap file separator characters to keep files with spaces in paths from breaking to two items as `find` output
OIFS="$IFS"
IFS=$'\n'

XCDANGER_SCHEMES=`find "${XCDANGER_PROJECT}"/xcshareddata -name "*.xcscheme"`
XCDANGER_CONFIGURATIONS=`xcodebuild -project "${XCDANGER_PROJECT}" -list | ruby scripts/list-configurations.rb`

XCDANGER_OUTPUT_PATH="${XCDANGER_PROJECT}/../.xcdanger"
mkdir -p "${XCDANGER_OUTPUT_PATH}"

function unexpand_setting {
	XCDANGER_SETTING_NAME="${1}"
	XCDANGER_UNEXPANDED_OUTPUT_FILE="${2}"
	
	# awk grabs the line containing the setting definition
	# cut discards the leading whitespace, THE_BUILD_SETTING_NAME and the '=', leaving just the value
	XCDANGER_COMMAND="awk '{if (\$1 == \"${XCDANGER_SETTING_NAME}\") print \$0;}' \"${XCDANGER_UNEXPANDED_OUTPUT_FILE}\" | cut -d' ' -f7-"
	# echo "${XCDANGER_COMMAND}"
	XCDANGER_VALUE=`eval "${XCDANGER_COMMAND}"`
	
	if [[ -n "${XCDANGER_VALUE}" ]]; then
		
		# replace each instance of the build setting value with the name of the build setting itself, writing to a temp file
		XCDANGER_TEMP_UNEXPANDED_OUTPUT_FILE="${XCDANGER_UNEXPANDED_OUTPUT_FILE}.new"
		XCDANGER_COMMAND="sed \"s%${XCDANGER_VALUE}%${XCDANGER_SETTING_NAME}%g\" \"${XCDANGER_UNEXPANDED_OUTPUT_FILE}\" > \"${XCDANGER_TEMP_UNEXPANDED_OUTPUT_FILE}\""
		# echo "${XCDANGER_COMMAND}"
		eval "${XCDANGER_COMMAND}"
		
		# swap the temp file into the original file's place, overwriting it
		rm "${XCDANGER_UNEXPANDED_OUTPUT_FILE}"
		mv "${XCDANGER_TEMP_UNEXPANDED_OUTPUT_FILE}" "${XCDANGER_UNEXPANDED_OUTPUT_FILE}"
	else
		echo "No value to unexpand for \"${XCDANGER_SETTING_NAME}\" in ${XCDANGER_UNEXPANDED_OUTPUT_FILE}"
	fi
}

XCDANGER_EXIT_CODE=0

for XCDANGER_CONFIGURATION in ${XCDANGER_CONFIGURATIONS[@]}; do
	for XCDANGER_SCHEME_PATH in ${XCDANGER_SCHEMES[@]}; do

		# get the scheme name from the .xcscheme path. 
		# replace spaces in name with escape-quoted space characters, so that basename doesn't break them to new lines either
		XCDANGER_SCHEME_NAME=`echo "${XCDANGER_SCHEME_PATH}" | sed s/' '/'\"\ \"'/g | xargs basename | sed s/'.xcscheme'//g`

		# file we'll write the settings to: /path/to/.../.xcdanger/<configuration>/<scheme-name>.build-settings.lock
		XCDANGER_OUTPUT_DIR="${XCDANGER_OUTPUT_PATH}/${XCDANGER_CONFIGURATION}"
		mkdir -p "${XCDANGER_OUTPUT_DIR}"
		XCDANGER_OUTPUT_FILE="${XCDANGER_OUTPUT_DIR}/${XCDANGER_SCHEME_NAME}.build-settings.lock"
		XCDANGER_TEMP_OUTPUT_FILE="${XCDANGER_OUTPUT_FILE}.new"

		# output the xcode build settings for the scheme/configuration
		xcodebuild -project "${XCDANGER_PROJECT}" -scheme "${XCDANGER_SCHEME_NAME}" -configuration "${XCDANGER_CONFIGURATION}" -showBuildSettings > "${XCDANGER_TEMP_OUTPUT_FILE}"

		# replace any user-specific paths with the variable name they were derived from
		XCDANGER_UNEXPANDED_SETTINGS=`cat lib/settings-to-unexpand`
		for XCDANGER_UNEXPANDED_SETTING in ${XCDANGER_UNEXPANDED_SETTINGS[@]}; do
			unexpand_setting "${XCDANGER_UNEXPANDED_SETTING}" "${XCDANGER_TEMP_OUTPUT_FILE}"
		done

		# if there's already a .lock file, see if any settings have changed; if so we'll return non-zero exit status at the end (-e checks if file exists)
		if [[ -e "${XCDANGER_OUTPUT_FILE}" ]]; then
			diff --brief "${XCDANGER_TEMP_OUTPUT_FILE}" "${XCDANGER_OUTPUT_FILE}" > /dev/null 2>&1
			XCDANGER_DIFF_RESULT=$?
			if [[ $XCDANGER_DIFF_RESULT -ne 0 ]]; then
				XCDANGER_EXIT_CODE=$XCDANGER_EXIT_BUILD_SETTINGS_CHANGED
			fi
			
			# remove the old lock file so we can move the new temp one into its place
			rm "${XCDANGER_OUTPUT_FILE}"
		fi

		# overwrite the existing files with the temporary ones
		mv "${XCDANGER_TEMP_OUTPUT_FILE}" "${XCDANGER_OUTPUT_FILE}"

	done
done

# replace the old file separator character
IFS="$OIFS"

exit $XCDANGER_EXIT_CODE
