#!/bin/bash
#
# disconnect.sh
# unmount remote filesystem over ssh if already mounted

dir_local="/Users/Liz/srv"

sudo fusermount -uz "$dir_local"
exit 0