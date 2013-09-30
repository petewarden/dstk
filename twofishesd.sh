#!/bin/sh
# The default locale for Upstart scripts is empty, which causes unicode argument
# parsing to silently fail in the TwoFishes Java server code!
export LANG=en_US.UTF-8
java -jar /home/ubuntu/sources/twofishes/bin/twofishes.jar --hfile_basepath /home/ubuntu/sources/twofishes/data/latest/
