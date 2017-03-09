# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
KEYWORDS="~amd64 ~ia64 ~ppc ~ppc64 ~sparc ~x86"

inherit autotools eutils linux-info systemd user versionator git-r3

MY_PV=$(get_version_component_range 1-2)

EGIT_CLONE_TYPE="shallow"
EGIT_REPO_URI="https://github.com/BOINC/boinc.git"

DESCRIPTION="The Berkeley Open Infrastructure for Network Computing"
HOMEPAGE="http://boinc.ssl.berkeley.edu/"
RESTRICT="mirror"

LICENSE="LGPL-2.1"
SLOT="0"
IUSE="cuda curl_ssl_libressl +curl_ssl_openssl static-libs"

REQUIRED_USE="^^ ( curl_ssl_libressl curl_ssl_openssl ) "

# libcurl must not be using an ssl backend boinc does not support.
# If the libcurl ssl backend changes, boinc should be recompiled.
RDEPEND="
	!sci-misc/boinc-bin
	!app-admin/quickswitch
	>=app-misc/ca-certificates-20080809
	net-misc/curl[-curl_ssl_gnutls(-),curl_ssl_libressl(-)=,-curl_ssl_nss(-),curl_ssl_openssl(-)=,-curl_ssl_axtls(-),-curl_ssl_cyassl(-),-curl_ssl_polarssl(-)]
	sys-apps/util-linux
	sys-libs/zlib
	cuda? (
		>=dev-util/nvidia-cuda-toolkit-2.1
		>=x11-drivers/nvidia-drivers-180.22
	)
"
DEPEND="${RDEPEND}
	sys-devel/gettext
	app-text/docbook-xml-dtd:4.4
	app-text/docbook2X
"

pkg_setup() {
	# Bug 578750
	if use kernel_linux; then
		linux-info_pkg_setup
		if ! linux_config_exists; then
			ewarn "Can't check the linux kernel configuration."
			ewarn "You might be missing vsyscall support."
		elif kernel_is -ge 4 4 \
		    && linux_chkconfig_present LEGACY_VSYSCALL_NONE; then
			ewarn "You do not have vsyscall emulation enabled."
			ewarn "This will prevent some boinc projects from running."
			ewarn "Please enable vsyscall emulation:"
			ewarn "    CONFIG_LEGACY_VSYSCALL_EMULATE=y"
			ewarn "in /usr/src/linux/.config, to be found at"
			ewarn "    Processor type and features --->"
			ewarn "        vsyscall table for legacy applications (None) --->"
			ewarn "            (X) Emulate"
			ewarn "Alternatively, you can enable CONFIG_LEGACY_VSYSCALL_NATIVE."
			ewarn "However, this has security implications and is not recommended."
		fi
	fi
}

src_prepare() {
	default

	# prevent bad changes in compile flags, bug 286701
	sed -i -e "s:BOINC_SET_COMPILE_FLAGS::" configure.ac || die "sed failed"

	eautoreconf
}

src_configure() {
	econf --disable-server \
		--enable-client \
		--enable-dynamic-client-linkage \
		--disable-static \
		--enable-unicode \
		--with-ssl \
		--without-x --disable-manager --without-wxdir
}

src_install() {
	default

	keepdir /var/lib/${PN}

	# cleanup cruft
	rm -rf "${ED%/}"/etc || die "rm failed"

	newinitd "${FILESDIR}"/${PN}.init ${PN}
	newconfd "${FILESDIR}"/${PN}.conf ${PN}
	systemd_dounit "${FILESDIR}"/${PN}.service
}

pkg_preinst() {
	enewgroup ${PN}
	# note this works only for first install so we have to
	# elog user about the need of being in video group
	local groups="${PN}"
	if use cuda; then
		groups+=",video"
	fi
	enewuser ${PN} -1 -1 /var/lib/${PN} "${groups}"
}

pkg_postinst() {
	elog
	elog "You are using the source compiled version of boinc."
	elog
	elog "You need to attach to a project to do anything useful with boinc."
	elog "You can do this by running /etc/init.d/boinc attach"
	elog "The howto for configuration is located at:"
	elog "http://boinc.berkeley.edu/wiki/Anonymous_platform"
	elog
	# Add warning about the new password for the client, bug 121896.
	if use cuda; then
		elog "To be able to use CUDA you should add boinc user to video group."
		elog "Run as root:"
		elog "gpasswd -a boinc video"
	fi
}
