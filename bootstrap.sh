#!/usr/bin/env bash

echo "Checks for required utils"

command -v ruby >/dev/null || {
    sudo apt-get install ruby
}

ruby bootstrap-main.rb
