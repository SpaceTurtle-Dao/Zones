#!/bin/bash

if [[ "$(uname)" == "Linux" ]]; then
    BIN_PATH="$HOME/.luarocks/bin"
else
    BIN_PATH="/opt/homebrew/bin"
fi

# GENERATE LUA in /build-lua
mkdir -p ./build
mkdir -p ./build-lua

# build teal
cyan build -u

cd build-lua

amalg.lua -s main.lua -o ../build/relay.lua \
    utils.bint utils.tl-utils \
    relay_systems.event_system \
    relay_systems.feed_system \
    relay_systems.profile_system \
    relay_systems.query_system \
    relay_systems.subscription_system \
    relay_systems.token_system \
    database \
    systems.systems


# FINAL RESULT is build/main.lua