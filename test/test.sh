#!/bin/sh

XCBS_WORKING_CHANGES=`git status --porcelain | wc -l`
if [[ ${XCBS_WORKING_CHANGES} -ne 0 ]]; then
	echo "You have uncommitted changes in your working directory. Stashing them until the tests complete."
	git stash --all
fi

XCBS_TEST_DIRECTORY="`pwd`/test"
XCBS_TEST_PROJECT_DIRECTORY="${XCBS_TEST_DIRECTORY}/Test Project"
XCBS_TEST_PROJECT="${XCBS_TEST_PROJECT_DIRECTORY}/Test Project.xcodeproj"
XCBS_TEST_XCCONFIG="${XCBS_TEST_PROJECT_DIRECTORY}/Test Project/Test.xcconfig"

XCBS_TEMP="${XCBS_TEST_XCCONFIG}.tmp"

# replace the value in the xcconfig, by redirecting sed STDOUT to temp file and swapping into actual file
sed 's/iphoneos/macosx10.12/g' "${XCBS_TEST_XCCONFIG}" > "${XCBS_TEMP}"
rm "${XCBS_TEST_XCCONFIG}"
mv "${XCBS_TEMP}" "${XCBS_TEST_XCCONFIG}"

# generate the new settings lock files
sh scripts/xcbs "${XCBS_TEST_PROJECT}"

# compare new git diff with the checked in baseline
XCBS_BASELINE_OUTPUT="${XCBS_TEST_DIRECTORY}/baseline.diff"
XCBS_TEST_OUTPUT="${XCBS_TEST_DIRECTORY}/computed.diff"
git diff "${XCBS_TEST_PROJECT_DIRECTORY}"/.xcbs/ "${XCBS_TEST_XCCONFIG}" > "${XCBS_TEST_OUTPUT}"

# see if new output is different from baseline
diff "${XCBS_TEST_OUTPUT}" "${XCBS_BASELINE_OUTPUT}" 
if [[ $? -eq 1 ]]; then
	echo
	echo "Test output differs from baseline output. If this is a deliberate change, run:"
	echo "\tmv ${XCBS_TEST_OUTPUT} ${XCBS_BASELINE_OUTPUT}"
	echo "and check in the changes to the baseline file."

	if [[ ${XCBS_WORKING_CHANGES} -ne 0 ]]; then
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

XCBS_TEST_OUTPUT_CLEAN_CMD="git clean -f \"${XCBS_TEST_OUTPUT}\""
echo "${XCBS_TEST_OUTPUT_CLEAN_CMD}"
eval "${XCBS_TEST_OUTPUT_CLEAN_CMD}"

echo

XCBS_TEST_DIRECTORY_CLEAN_CMD="git checkout \"${XCBS_TEST_DIRECTORY}\""
echo "${XCBS_TEST_DIRECTORY_CLEAN_CMD}"
eval "${XCBS_TEST_DIRECTORY_CLEAN_CMD}"

if [[ ${XCBS_WORKING_CHANGES} -ne 0 ]]; then
	echo
	echo "Popping stashed changes present before running tests..."
	git stash pop
fi
