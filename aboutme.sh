#!/bin/bash

echo
echo "Hello $(id -nu), that is your effective username"
echo "Your EUID is $(id -u)"
echo "Your RUID is $(id -ru)"
echo
echo "Your effective group is: $(id -ng)"
echo "Your EGID is $(id -g)"
echo "Your RGID is $(id -rg)"
echo
echo "You are a member of these groups:"
echo "$(id -nG)"
echo
echo "of which the EGIDs are: $(id -G)"
echo "of which the RGIDS are: $(id -rG)"
echo
echo "and the summary of that is:"
echo "$(id)"
echo
echo "Have a nice day!"