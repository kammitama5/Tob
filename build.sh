#!/bin/bash
REPOROOT=$(pwd)

DEPENDIR="${REPOROOT}/dependencies"
mkdir -p "${DEPENDIR}"

echo "Building Tor.framework and Iobfs4proxy.framework with Carthage..."
cd "${REPOROOT}"
carthage update --platform iOS --use-submodules --verbose

# cp "${REPOROOT}/Carthage/Checkouts/Tor.framework/Tor/tor/src/config/geoip" "${DEPENDIR}/geoip"
# cp "${REPOROOT}/Carthage/Checkouts/Tor.framework/Tor/tor/src/config/geoip6" "${DEPENDIR}/geoip6"
cp -R "${REPOROOT}/Carthage/Build/iOS/Tor.framework" "${DEPENDIR}/Tor.framework"
cp -R "${REPOROOT}/Carthage/Build/iOS/Iobfs4proxy.framework" "${DEPENDIR}/Iobfs4proxy.framework"

BUILDDIR="${REPOROOT}/build"
mkdir -p "${BUILDDIR}"

SRCDIR="${BUILDDIR}/src"
mkdir -p "${SRCDIR}"
cd "${SRCDIR}"

echo $'\nDownloading geoip file from https://github.com/torproject/tor...'
curl -o geoip https://raw.githubusercontent.com/torproject/tor/master/src/config/geoip
cp "${SRCDIR}/geoip" "${DEPENDIR}/geoip"

echo $'\nDownloading geoip6 file from https://github.com/torproject/tor...'
curl -o geoip6 https://raw.githubusercontent.com/torproject/tor/master/src/config/geoip6
cp "${SRCDIR}/geoip6" "${DEPENDIR}/geoip6"

echo $'\nCleaning up...'
cd "${REPOROOT}"
rm "Cartfile.resolved"
rm -rf "${BUILDDIR}"
rm -rf "${REPOROOT}/Carthage"

echo "Done!"