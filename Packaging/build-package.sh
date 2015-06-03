#!/bin/sh

#  build-package.sh
#  TimeLapse
#
#  Created by Jim Studt on 2/11/14.
#  Copyright (c) 2014 Lunarware. All rights reserved.

set -e

if ( echo "${BUILT_PRODUCTS_DIR}" | fgrep "/Debug/" ) ;then
    echo You are trying to build a package of a Debug release. Not what you want.
    exit 1
fi

CERTIFICATE_CN="Developer ID Installer: James Studt (HJS98U3F75)"

VERSION=$(sed -E -n -e 's/#define *TIMELAPSE_VERSION *"([^"]*)"/\1/p' "${SOURCE_ROOT}"/Version.h)
PACKAGE_NAME=`echo "$PRODUCT_NAME" | sed "s/ /_/g"`

FAKEROOT=${BUILT_PRODUCTS_DIR}/install-usr
COMPONENT_PACKAGE=${BUILT_PRODUCTS_DIR}/timelapse.pkg

rm -rf "${FAKEROOT}"
mkdir "${FAKEROOT}"
mkdir -p "${FAKEROOT}/usr/local/bin"
mkdir -p "${FAKEROOT}/usr/local/share/man/man1"
cp "${BUILT_PRODUCTS_DIR}/timelapse" "${FAKEROOT}/usr/local/bin/"
cp "${SOURCE_ROOT}/timelapse.1" "${FAKEROOT}/usr/local/share/man/man1/"

pkgbuild --root "${FAKEROOT}" \
    --identifier com.lunarware.timelapse \
    --version "${VERSION}" \
    --ownership recommended \
    --sign "${CERTIFICATE_CN}" \
    "${COMPONENT_PACKAGE}"


