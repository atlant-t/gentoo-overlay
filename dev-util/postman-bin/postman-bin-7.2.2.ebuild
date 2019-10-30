# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop

DESCRIPTION="Postman API Client for linux"
HOMEPAGE="https://www.getpostman.com/product/api-client"
SLOT="0"

KEYWORDS="x86 amd64"

POSTMAN_URI="https://dl.pstmn.io/download/"

BUILD_PN="${PN/-bin}"

SRC_URI="${SRC_URI}
  x86? ( ${POSTMAN_URI%/}/version/${PV}/linux32 -> ${BUILD_PN}-linux-ia32-${PV}.tar.gz )
  amd64? ( ${POSTMAN_URI%/}/version/${PV}/linux64 -> ${BUILD_PN}-linux-x64-${PV}.tar.gz )"

LICENSE="Postman-free"

pkg_setup(){
  S="${WORKDIR}/Postman"
}

src_install(){
  mkdir -p "${ED}/opt/${BUILD_PN}"
  cp -r ./app/* "${ED}/opt/${BUILD_PN}/"
  dosym "/opt/${BUILD_PN}/Postman" "/usr/bin/${BUILD_PN}"
  make_desktop_entry "${BUILD_PN}" "Postman" "${BUILD_PN}" "Development;Util"
  newicon "app/resources/app/assets/icon.png" ${BUILD_PN}.png
  einstalldocs
}
