#!/bin/sh

#  notarize.sh
#  TimeLapse
#
#  Created by Jim Studt on 12/29/19.
#  Copyright © 2019 Lunarware. All rights reserved.

xcrun altool --notarize-app \
--primary-bundle-id "com.lunarware.timelapse" \
--username "jim@studt.net" \
--password "@keychain:Developer-altool" \
--file "build/timelapse.pkg"

#--asc-provider "8VFWL42C8C"   -- needed if memebrs of more than one team, isn't working for me.

