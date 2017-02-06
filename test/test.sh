#!/bin/sh

XCDANGER_TEST_DIRECTORY="`pwd`/test/Test Project"
XCDANGER_TEST_PROJECT="${XCDANGER_TEST_DIRECTORY}/Test Project.xcodeproj"
echo "XCDANGER_TEST_PROJECT: ${XCDANGER_TEST_PROJECT}"

XCDANGER_TEST_PROJECT_MODEL="${XCDANGER_TEST_PROJECT}/project.pbxproj"
XCDANGER_TEMP="${XCDANGER_TEST_PROJECT}.tmp"

sed 's/SDKROOT = iphoneos;/SDKROOT = macosx10.12;/g' "${XCDANGER_TEST_PROJECT_MODEL}" > "${XCDANGER_TEMP}"

rm "${XCDANGER_TEST_PROJECT_MODEL}"
mv "${XCDANGER_TEMP}" "${XCDANGER_TEST_PROJECT_MODEL}"

sh output-build-settings.sh "${XCDANGER_TEST_PROJECT}"

XCDANGER_BASELINE_OUTPUT="test/baseline_diff.patch"
XCDANGER_TEST_OUTPUT="test/computed_diff.patch"

git diff > "${XCDANGER_TEST_OUTPUT}"

# see if new output is different from baseline
diff "${XCDANGER_TEST_OUTPUT}" "${XCDANGER_BASELINE_OUTPUT}" 
if [[ $? == 1 ]]; then
	echo
	echo "Test output differs from baseline output. If this is a deliberate change, run:"
	echo 
	echo "\tmv ${XCDANGER_TEST_OUTPUT} ${XCDANGER_BASELINE_OUTPUT}"
	echo
	echo "and check in the changes to the baseline file."
	exit 1
fi

echo "Test succeeded."

XCDANGER_TEST_OUTPUT_CLEAN_CMD="git clean -f \"${XCDANGER_TEST_OUTPUT}\""
echo "${XCDANGER_TEST_OUTPUT_CLEAN_CMD}"
eval "${XCDANGER_TEST_OUTPUT_CLEAN_CMD}"

XCDANGER_TEST_DIRECTORY_CLEAN_CMD="git checkout \"${XCDANGER_TEST_DIRECTORY}\""
echo "${XCDANGER_TEST_DIRECTORY_CLEAN_CMD}"
eval "${XCDANGER_TEST_DIRECTORY_CLEAN_CMD}"
