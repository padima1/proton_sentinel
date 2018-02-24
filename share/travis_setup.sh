#!/bin/bash
set -evx

mkdir ~/.protoncore

# safety check
if [ ! -f ~/.protoncore/.proton.conf ]; then
  cp share/proton.conf.example ~/.protoncore/proton.conf
fi
