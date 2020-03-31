#! /bin/bash

NEW_JITSI_MEET_VER=$1
NEW_COMP_VERSION=$2
NEW_VERSION=$3

echo $NEW_VERSION > $NEW_COMP_VERSION

cp control-tmpl debian/control

JVB_VER=`cat jitsi-videobridge`
JICOFO_VER=`cat jicofo`
JITSI_MEET_WEB_VER=`cat jitsi-meet-web`
sed -i.bak  -e "s/__JVB_VER__/$JVB_VER-1/" debian/control
sed -i.bak  -e "s/__JICOFO_VER__/1.0-$JICOFO_VER-1/" debian/control
sed -i.bak  -e "s/__JITSI_MEET_WEB_VER__/1.0.$JITSI_MEET_WEB_VER-1/" debian/control

export DEBFULLNAME="Jitsi Team"
export DEBEMAIL="dev@jitsi.org"
dch -v "2.0.$NEW_JITSI_MEET_VER-1" "Build using jitsi-videobridge: $JVB_VER, jicofo: $JICOFO_VER, jitsi-meet-web: $JITSI_MEET_WEB_VER"
dch -D unstable -r ""

dpkg-buildpackage -A -rfakeroot -us -uc

debian/rules clean
git checkout debian/changelog
rm debian/control
