#!/bin/sh

XCDANGER_WORKING_CHANGES=`git status --porcelain | wc -l`
if [[ ${XCDANGER_WORKING_CHANGES} -ne 0 ]]; then
	echo "You have uncommitted changes in your working directory. Stashing them until the tests complete."
	git stash --all
fi

XCDANGER_TEST_DIRECTORY="`pwd`/test"
XCDANGER_TEST_PROJECT_DIRECTORY="${XCDANGER_TEST_DIRECTORY}/Test Project"
XCDANGER_TEST_PROJECT="${XCDANGER_TEST_PROJECT_DIRECTORY}/Test Project.xcodeproj"
XCDANGER_TEST_XCCONFIG="${XCDANGER_TEST_PROJECT_DIRECTORY}/Test Project/Test.xcconfig"

XCDANGER_TEMP="${XCDANGER_TEST_XCCONFIG}.tmp"

# replace the value in the xcconfig, by redirecting sed STDOUT to temp file and swapping into actual file
sed 's/iphoneos/macosx10.12/g' "${XCDANGER_TEST_XCCONFIG}" > "${XCDANGER_TEMP}"
rm "${XCDANGER_TEST_XCCONFIG}"
mv "${XCDANGER_TEMP}" "${XCDANGER_TEST_XCCONFIG}"

# generate the new settings lock files
sh scripts/output-build-settings.sh "${XCDANGER_TEST_PROJECT}"

# we expect differences, and the exit code should be 3
XCDANGER_EXIT_STATUS=$?
if [[ $XCDANGER_EXIT_STATUS -ne 3 ]]; then
	echo "Expected exit code of 3 but got ${XCDANGER_EXIT_STATUS}"
	exit 1
fi

# compare new git diff with the checked in baseline
XCDANGER_BASELINE_OUTPUT="${XCDANGER_TEST_DIRECTORY}/baseline.diff"
XCDANGER_TEST_OUTPUT="${XCDANGER_TEST_DIRECTORY}/computed.diff"
git diff "${XCDANGER_TEST_PROJECT_DIRECTORY}"/.xcdanger/ "${XCDANGER_TEST_XCCONFIG}" > "${XCDANGER_TEST_OUTPUT}"

# see if new output is different from baseline
diff "${XCDANGER_TEST_OUTPUT}" "${XCDANGER_BASELINE_OUTPUT}" 
if [[ $? -eq 1 ]]; then
	echo
	echo "Test output differs from baseline output. If this is a deliberate change, run:"
	echo "\tmv ${XCDANGER_TEST_OUTPUT} ${XCDANGER_BASELINE_OUTPUT}"
	echo "and check in the changes to the baseline file."

	if [[ ${XCDANGER_WORKING_CHANGES} -ne 0 ]]; then
		echo
		echo "You had uncommitted changes before running the tests, which are currently stashed. Don't forget about them!"
	fi

	exit 1
fi

echo
echo "/-----------------\\"
echo "| Test succeeded! |"
echo "\-----------------/"
echo

echo "Cleaning up..."
echo

XCDANGER_TEST_OUTPUT_CLEAN_CMD="git clean -f \"${XCDANGER_TEST_OUTPUT}\""
echo "${XCDANGER_TEST_OUTPUT_CLEAN_CMD}"
eval "${XCDANGER_TEST_OUTPUT_CLEAN_CMD}"

echo

XCDANGER_TEST_DIRECTORY_CLEAN_CMD="git checkout \"${XCDANGER_TEST_DIRECTORY}\""
echo "${XCDANGER_TEST_DIRECTORY_CLEAN_CMD}"
eval "${XCDANGER_TEST_DIRECTORY_CLEAN_CMD}"

if [[ ${XCDANGER_WORKING_CHANGES} -ne 0 ]]; then
	echo
	echo "Popping stashed changes present before running tests..."
	git stash pop
fi
