#!/bin/bash
set -euo pipefail

tags=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases | \
       jq -r '.[].tag_name')

if [ -z "$tags" ]; then
    echo "No tags found or unable to fetch data."
    exit 1
fi

echo
echo "Available release tags:"

tags_per_line=4
count=0

for tag in $tags; do
    printf "%s\t" "$tag"
    count=$((count + 1))
    
    if (( count % tags_per_line == 0 )); then
        echo
    fi
done

if (( count % tags_per_line != 0 )); then
    echo
fi

echo
read -p "Please enter a tag from the list above: " selected_tag
echo

if echo "$tags" | grep -q "^$selected_tag$"; then
    echo "You selected: $selected_tag"
else
    echo "Invalid selection. Please choose a valid tag from the list."
    exit 1
fi

echo "Creating temporary working directory..."
rm -rf /tmp/proton-ge-custom
mkdir /tmp/proton-ge-custom
cd /tmp/proton-ge-custom

echo "Fetching tarball URL..."

tarball_url=$(curl -s "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/tags/$selected_tag" | grep browser_download_url | cut -d\" -f4 | grep .tar.gz)
tarball_name=$(basename $tarball_url)

echo "Downloading tarball: $tarball_name..."
curl -# -L $tarball_url -o $tarball_name --no-progress-meter

echo "Fetching checksum URL..."
checksum_url=$(curl -s "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/tags/GE-Proton8-7" | grep browser_download_url | cut -d\" -f4 | grep .sha512sum)
checksum_name=$(basename $checksum_url)
echo "Downloading checksum: $checksum_name..."
curl -# -L $checksum_url -o $checksum_name --no-progress-meter

echo "Verifying tarball $tarball_name with checksum $checksum_name..."
sha512sum -c $checksum_name

echo "Creating Steam directory if it does not exist..."
mkdir -p ~/.steam/steam/compatibilitytools.d

echo "Extracting $tarball_name to Steam directory..."
tar -xf $tarball_name -C ~/.steam/steam/compatibilitytools.d/

echo "$selected_tag successfully installed; you may need to restart Steam to see the changes."
