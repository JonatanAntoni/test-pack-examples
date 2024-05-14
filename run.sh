#!/usr/bin/env bash

config=${1-test.json}
if [ ! -f "$config" ]; then
    echo "Config file not found: '$config'"
    exit 1
fi

mkdir -p build

for i in $(seq "$(jq -r ".examples|length" < "$config")"); do
    pack=$(jq -r ".examples[$i-1].pack" < "$config")
    project=$(jq -r ".examples[$i-1].project" < "$config")
    context=$(jq -r ".examples[$i-1].context" < "$config")
    folder=$(cpackget add -a "$pack" | grep -e "Extracting files to" -e "is already installed here" | sed -e "s/.*Extracting files to \(.*\).../\1/" | sed -e  "s/.* is already installed here: \"\([^\"]*\)\".*/\1/")
    echo "$pack: $project[$context]"
    source=$(dirname "$folder/$project")
    target="build/$(basename "$source")"
    cp -rf "$source" build
    pushd "$target" || exit
    chmod -R u+w .
    cbuild -r -v -p --update-rte "$(basename "$project")" -c "$context" || echo "::error::Compilation of project $project[$context] in $pack failed!"
    popd || exit
done
