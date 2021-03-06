#!/bin/bash
#
# Find all the new packages that are in the simple puddle
#  And put them into the errata builds
#
############
# VARIABLES
############
TMPDIR=$(mktemp -d /tmp/simple-to-errata-XXXXXX)
#VERSION="3.5"
VERSION="${1}"
SIMPLELINK="building"
ERRATALINK="building"
RELEASEVERSION="RHEL-7-OSE-${VERSION}"
BASEDIR="/mnt/rcm-guest/puddles/RHAOS"
SIMPLEDIR="${BASEDIR}/AtomicOpenShift/${VERSION}/${SIMPLELINK}/x86_64/os/Packages"
ERRATADIR="${BASEDIR}/AtomicOpenShift-errata/${VERSION}/${ERRATALINK}/RH7-RHAOS-${VERSION}/x86_64/os/Packages"
GITEXCLUDE="-e cockpit -e atomic-openshift-clients-redistributable -e openshift-clients-redistributable -e python-jsonschema -e python-ruamel-yaml -e python-wheel -e python-typing -e python-ruamel-ordereddict -e openshift-ansible"

# Figure out the ERRATAID
#ERRATAID="25181"
ERRATAID=$(grep "::${VERSION}::" errata.list | awk '{print $2}')
if [ "${ERRATAID}" == "" ] || [ "${ERRATAID}" == "NONE" ] ; then
  echo "  No Errata listed for ${VERSION}"
  echo "  Exiting."
  exit 1
fi

# Find out differences, put them in a file
diff --brief -r ${SIMPLEDIR}/ ${ERRATADIR}/ | grep "${SIMPLEDIR}" | grep -v ${GITEXCLUDE} | awk '{print "'${SIMPLEDIR}'/" $4}' | while read line
do
  rpm -qp --qf "%{SOURCERPM}\n" $line | grep -v ${GITEXCLUDE} >> ${TMPDIR}/sourcerpm
done

if [ -s ${TMPDIR}/sourcerpm ] ; then
  # massage our differences into nvr instances
  sort -u -o ${TMPDIR}/sourcerpm ${TMPDIR}/sourcerpm
  #cat ${TMPDIR}/sourcerpm
  cat ${TMPDIR}/sourcerpm | rev | cut -d'.' -f3- | rev > ${TMPDIR}/nvr
  #cat ${TMPDIR}/nvr
  echo "New Packages:"
  cat ${TMPDIR}/nvr
  echo
  # Update the errata
  cat ${TMPDIR}/nvr | while read thisnvr
  do
    echo "  Adding ${thisnvr} to errata ...."
    ./et_add_build ${ERRATAID} ${RELEASEVERSION} ${thisnvr}
  done
else
  echo "  No differences found."
fi

# Cleanup temp directory
rm -rf ${TMPDIR}
