# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

LICENSE="no-source-code"
DESCRIPTION="Kerio Control VPN Client
 Internet access management for corporate networks."
HOMEPAGE="https://www.kerio.com/"

CFGFILE="/etc/kerio-kvc.conf"
SERVICE_NAME="kerio-kvc"
KEYWORDS="~x86 ~amd64"

KERIO_REV="3673"
KERIO_URI="http://cdn.kerio.com/dwn/control/control-${PV}-${KERIO_REV}/${PN}-${PV}-${KERIO_REV}-linux"
SRC_URI="
  x86? ( ${KERIO_URI}.deb )
  amd64? ( ${KERIO_URI}-amd64.deb )
"

IUSE="libuuid"
DEPEND="sys-devel/binutils
        sys-apps/grep
        app-shells/bash
        sys-libs/glibc
        sys-devel/gcc[cxx]
        libuuid? ( sys-libs/libuuid )
        !libuuid? ( sys-apps/util-linux )
        sys-process/procps
        dev-libs/openssl"
RDEPEND="${DEPEND}"
CONFIG_PROTECT="${CFGFILE}"

SLOT="0"

pkg_setup(){
  S="${WORKDIR}/data"
}

src_unpack() {
  ar x ${DISTDIR}/${A}

  for ARCHIVE in $(ls | grep \.tar); do 
    mkdir ${ARCHIVE%%.*}
    cd ${ARCHIVE%%.*}
    unpack ../${ARCHIVE}
    cd ../
  done
}

src_prepare() {

  S="${WORKDIR}/data"

  cat > "${S}${CFGFILE}" << EOF
<config>
  <connections>
    <connection type="persistent">
      <server>SERVER_ADDRESS</server>
      <port>PORT</port>
      <username>USERNAME</username>
      <password>XOR:\$(PASSWORD="YOUR PASSWORD"; for i in \`echo -n "\$PASSWORD" | od -t d1 -A n\`; do XOR=\$(printf "%s%02x" "\$XOR" \$((i ^ 85))); done; echo \${XOR})</password>
      <fingerprint>\$(echo | openssl s_client -connect SERVER_ADDRESS:PORT | openssl x509 -fingerprint -md5 -noout | sed s'/.*=//')</fingerprint>
      <active>1</active>
    </connection>
  </connections>
</config>
EOF

  eapply_user
}

src_install() {
  S=${WORKDIR}/data

  into /usr
  dolib.so ${S}/usr/lib/*

  exeinto /usr/sbin
  doexe ${S}/usr/sbin/*

  insinto /usr/share
  doins -r ${S}/usr/share/lintian

  docinto /
  dodoc ${S}/usr/share/doc/${PN}/*

  insinto /etc/init.d
  doins ${S}/etc/init.d/${SERVICE_NAME}

  insinto /etc
  doins ${S}/${CFGFILE}
}

pkg_postinst() {
  chmod 0600 "$CFGFILE"
  chmod +x /etc/init.d/${SERVICE_NAME}

  LDCONFIG_NOTRIGGER=y ldconfig

  pkg_info
}

pkg_info() {
  elog "To configure Kerio Control VPN Client edit"
  elog "* ${CFGFILE}"
  elog " "
  elog "To automatically start ${SERVICE_NAME} run"
  elog "rc-config add ${SERVICE_NAME}"
  elog "rc-config start ${SERVICE_NAME}"
  elog " "
  elog "Encode password (to XOR) to put in ${CFGFILE}:"
  elog "echo \$(PASSWORD=\"YOUR PASSWORD\"; for i in \`echo -n \"\$PASSWORD\" | od -t d1 -A n\`; do XOR=\$(printf \"%s%02x\" \"\$XOR\" \$((i ^ 85))); done; echo \${XOR})"
  elog " "
  elog "Get server fingerprint to put in ${CFGFILE}:"
  elog "echo \"Server fingerprint: \$(echo | openssl s_client -connect SERVER_ADDRESS:PORT | openssl x509 -fingerprint -md5 -noout | sed s'/.*=//')\""
}

pkg_prerm() {
  rc-config stop ${SERVICE_NAME} || true
}

pkg_postrm() {
  ldconfig
  rc-config delete ${SERVICE_NAME} >/dev/null || true
}
