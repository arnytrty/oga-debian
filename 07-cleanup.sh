#!/bin/bash

ls | grep -v .sh | grep -v oga-debian.img | xargs rm -r
rm /opt/toolchains -rf
