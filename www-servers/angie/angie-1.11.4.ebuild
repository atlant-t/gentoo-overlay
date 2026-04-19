# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

# TODO: Add support for ntls. This may require adding
# the [Tongsuo](https://github.com/Tongsuo-Project/Tongsuo) library.
# See https://github.com/Tongsuo-Project/Tongsuo/issues/421
#
# TODO: Research perl module and add addition configurations.
#
# TODO: Check if FastCGI depends on the RealIP module or find out way nginx
# ebuild has fallowing code on configuration:
# ```
# if use nginx_modules_http_fastcgi; then
# 	myconf+=( --with-http_realip_module )
# fi
# ```

DESCRIPTION="Efficient, powerful, and scalable web server that was forked from nginx"
HOMEPAGE="https://en.angie.software/"
SRC_URI="https://download.angie.software/files/${P}.tar.gz"

LICENSE="BSD-2"

SLOT="0"
KEYWORDS="amd64"

ANGIE_MODULES_HTTP_STD="
	access api auth_basic autoindex browser charset empty_gif fastcgi geo gzip
	grpc limit_conn limit_req map memcached mirror proxy prometheus referer
	rewrite scgi split_clients ssi upstream_hash upstream_ip_hash
	upstream_keepalive upstream_least_conn upstream_random upstream_sticky
	upstream_zone userid uwsgi
"

ANGIE_MODULES_HTTP_OPT="
	acme addition auth_request dav degradation flv geoip gunzip gzip_static image_filter
	mp4 perl random_index realip secure_link slice stub_status sub xslt
"

ANGIE_MODULES_MAIL_STD="imap pop3 smtp"

ANGIE_MODULES_MAIL_OPT=""

ANGIE_MODULES_STREAM_STD="
	geo limit_conn map return set split_clients upstream_hash
	upstream_least_conn upstream_random upstream_zone
"

ANGIE_MODULES_STREAM_OPT="geoip mqtt_preread rdp_preread realip ssl_preread"

IUSE="debug test aio +http +http2 http3 +http-cache ssl ktls threads pcre +pcre2 pcre-jit"

for mod in $ANGIE_MODULES_HTTP_STD; do
	IUSE="${IUSE} +angie_modules_http_${mod}"
done

for mod in $ANGIE_MODULES_HTTP_OPT; do
	IUSE="${IUSE} angie_modules_http_${mod}"
done

for mod in $ANGIE_MODULES_MAIL_STD; do
	IUSE="${IUSE} angie_modules_mail_${mod}"
done

for mod in $ANGIE_MODULES_MAIL_OPT; do
	IUSE="${IUSE} angie_modules_mail_${mod}"
done

for mod in $ANGIE_MODULES_STREAM_STD; do
	IUSE="${IUSE} angie_modules_stream_${mod}"
done

for mod in $ANGIE_MODULES_STREAM_OPT; do
	IUSE="${IUSE} angie_modules_stream_${mod}"
done

CDEPEND="
	acct-user/angie
	acct-group/angie
	ssl? (
		virtual/libcrypt:=
		dev-libs/openssl:0=
		http2? ( >=dev-libs/openssl-1.0.1c:0= )
	)
	ktls? ( >=dev-libs/openssl-3:0=[ktls] )
	pcre? ( dev-libs/libpcre:= )
	pcre2? ( dev-libs/libpcre2:=[unicode] )
	pcre-jit? ( dev-libs/libpcre:=[jit] )
	angie_modules_http_geoip? ( dev-libs/geoip )
	angie_modules_http_gunzip? ( sys-libs/zlib )
	angie_modules_http_gzip? ( sys-libs/zlib )
	angie_modules_http_gzip_static? ( sys-libs/zlib )
	angie_modules_http_image_filter? ( media-libs/gd:=[jpeg,png] )
	angie_modules_http_prometheus? ( app-metrics/prometheus )
	angie_modules_http_perl? ( >=dev-lang/perl-5.8.6:= )
	angie_modules_stream_geoip? ( dev-libs/geoip )
"

RDEPEND="${CDEPEND}"

DEPEND="${CDEPEND}"

BDEPEND="
	test? (
		dev-lang/perl
		dev-perl/Cache-Memcached
		dev-perl/Cache-Memcached-Fast
		dev-perl/CryptX
		dev-perl/FCGI
		ssl? ( dev-perl/GD )
		dev-perl/Net-SSLeay
		dev-perl/Test-Deep
		dev-perl/IO-Socket-SSL
		dev-perl/Test-Most
	)
"

REQUIRED_USE="
	angie_modules_http_rewrite? ( || ( pcre pcre2 ) )
	angie_modules_http_acme? ( ssl angie_modules_http_rewrite )
"

RESTRICT="!test? ( test )"

pkg_setup() {
	ANGIE_HOME="/var/lib/${PN}"
	ANGIE_HOME_TMP="${ANGIE_HOME}/tmp"
}

src_configure() {
	local uconf=() http_enabled= mail_enabled= stream_enabled=

	for mod in $ANGIE_MODULES_HTTP_STD; do
		if use angie_modules_http_${mod}; then
			http_enabled=1
		else
			uconf+=( --without-http_${mod}_module )
		fi
	done

	for mod in $ANGIE_MODULES_HTTP_OPT; do
		if use angie_modules_http_${mod}; then
			http_enabled=1
			uconf+=( --with-http_${mod}_module )
		fi
	done

	for mod in $ANGIE_MODULES_MAIL_STD; do
		if use angie_modules_mail_${mod}; then
			mail_enabled=1
		else
			uconf+=( --without-mail_${mod}_module )
		fi
	done

	for mod in $ANGIE_MODULES_MAIL_OPT; do
		if use angie_modules_mail_${mod}; then
			mail_enabled=1
			uconf+=( --with-mail_${mod}_module )
		fi
	done

	for mod in $ANGIE_MODULES_STREAM_STD; do
		if use angie_modules_stream_${mod}; then
			stream_enabled=1
		else
			uconf+=( --without-stream_${mod}_module )
		fi
	done

	for mod in $ANGIE_MODULES_STREAM_OPT; do
		if use angie_modules_stream_${mod}; then
			stream_enabled=1
			uconf+=( --with-stream_${mod}_module )
		fi
	done

	use debug       && uconf+=( --with-debug )
	use aio         && uconf+=( --with-file-aio )
	use ktls        && uconf+=( --with-openssl-opt=enable-ktls )
	use threads     && uconf+=( --with-threads )
	use pcre        && uconf+=( --with-pcre )
	use pcre-jit    && uconf+=( --with-pcre-jit )
	use pcre2       || uconf+=( --without-pcre2 )

	if use http || use http2 || use http3 || use http-cache; then
		http_enabled=1
	fi

	if [ $http_enabled ]; then
		use http-cache  || uconf+=( --without-http-cache )
		use ssl         && uconf+=( --with-http_ssl_module )
	else
		uconf+=( --without-http --without-http-cache )
	fi

	if use http2; then
		uconf+=( --with-http_v2_module )
	fi

	if use http3; then
		uconf+=( --with-http_v3_module )
	fi

	if [ mail_enabled ]; then
		uconf+=( --with-mail )
		use ssl && uconf+=( --with-mail_ssl_module )
	fi

	if [ $stream_enabled ]; then
		uconf+=( --with-stream )
		use ssl && uconf+=( --with-stream_ssl_module )
	fi

	./configure \
		--user=angie --group=angie \
		--prefix="${EPREFIX}"/usr/lib/${PN} \
		--sbin-path="${EPREFIX}"/usr/sbin/${PN} \
		--conf-path="${EPREFIX}"/etc/${PN}/${PN}.conf \
		--error-log-path="${EPREFIX}"/var/log/${PN}/error_log \
		--pid-path="${EPREFIX}"/run/${PN}/${PN}.pid \
		--lock-path="${EPREFIX}"/run/lock/${PN}.lock \
		--with-cc-opt="-I${ESYSROOT}/usr/include" \
		--with-ld-opt="-L${ESYSROOT}/usr/$(get_libdir)" \
		--http-log-path="${EPREFIX}"/var/log/${PN}/access_log \
		--http-client-body-temp-path="${EPREFIX}${ANGIE_HOME_TMP}"/client \
		--http-proxy-temp-path="${EPREFIX}${ANGIE_HOME_TMP}"/proxy \
		--http-fastcgi-temp-path="${EPREFIX}${ANGIE_HOME_TMP}"/fastcgi \
		--http-scgi-temp-path="${EPREFIX}${ANGIE_HOME_TMP}"/scgi \
		--http-uwsgi-temp-path="${EPREFIX}${ANGIE_HOME_TMP}"/uwsgi \
		--http-acme-client-path="${EPREFIX}${ANGIE_HOME}"/acme \
		--with-compat \
		"${uconf[@]}" || die "Configure failed. Use flags: ${uconf[@]}"
}

src_compile() {
	emake || die "Compile failed."
}

src_test() {
	pushd ${S}/tests > /dev/null || die "Tests not found"

	# Some tests failed so them are removed.
	# TODO: Check if the issue is reproducible in removed tests
	# and remove the removing code if possible.

	# The binary_upgrade.t test is excluded because
	# there is issue with process detection in ps
	# due to a very long path.
	rm ${S}/tests/binary_upgrade.t

	local -x TEST_ANGIE_BINARY="${S}/objs/angie"
	local -x TEST_ANGIE_VERBOSE=1
	local -x TEST_ANGIE_LEAVE=1

	prove -v . || die "Tests failed"
	popd > /dev/null || die "Something went wrong"
}

src_install() {
	emake DESTDIR="${D}" install

	newinitd "${FILESDIR}"/angie.initd angie
	newconfd "${FILESDIR}"/angie.confd angie
	systemd_newunit "${FILESDIR}"/angie.service angie.service

	doman man/angie.8
	dodoc CHANGES* README

	# set up a list of directories to keep
	local keepdir_list=()
	keepdir_list+=( "${ANGIE_HOME_TMP}"/client )

	for module in proxy fastcgi scgi uwsgi; do
		use angie_modules_http_${module} && keepdir_list+=( "${ANGIE_HOME_TMP}"/${module} )
	done

	keepdir /var/log/angie ${keepdir_list}

	# Moving the default HTML files to another folder to avoid overwriting
	# existing files. User can get these files with `emerge --config` or copy
	# them manually.
	dodir ${ANGIE_HOME}/examples
	mv ${ED}/usr/lib/${PN}/html ${ED}/${ANGIE_HOME}/examples

	fowners 0:${PN} "${ANGIE_HOME_TMP}"
	fperms 0760 "${ANGIE_HOME_TMP}"

	fowners -R ${PN}:${PN} ${keepdir_list}
	fperms 0740 ${keepdir_list}

	fowners 0:${PN} /var/log/${PN}
	fperms 0750 /var/log/${PN}

	# logrotate
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/angie.logrotate angie

	# Don't create /run
	rm -rf "${ED}"/run || die
}

pkg_postinst() {
	if [[ -z "${REPLACING_VERSIONS}" ]] || ([ ! -d /usr/lib/${PN}/html ] || [ -z "$( ls /usr/lib/${PN}/html )" ]); then
		elog "When installing Angie for the first time, you may wish to use"
		elog "the default HTML files. To do this, simply execute the command:"
		elog "# emerge --config ${CATEGORY}/${PN}"
	fi
}

pkg_config() {
	cp -ir ${EROOT}${ANGIE_HOME}/examples/html ${EROOT}/usr/lib/${PN}
}

