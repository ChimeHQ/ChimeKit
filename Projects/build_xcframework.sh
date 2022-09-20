#!/bin/sh

set -uxo pipefail

if [ "$CONFIGURATION" != "Release" ] ; then
    echo "error: must be built for release"
    exit 1
fi

OUTPUT_PATH="${SRCROOT}/../ChimeKit.xcframework"
rm -r ${OUTPUT_PATH}

xcodebuild -create-xcframework -framework ${BUILT_PRODUCTS_DIR}/ChimeKit.framework -debug-symbols ${BUILT_PRODUCTS_DIR}/ChimeKit.framework.dSYM -output ${OUTPUT_PATH}
