# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils git-r3

DESCRIPTION="Open source polyphonic software synthesizer with lots of modulation"
HOMEPAGE="http://tytel.org/helm/"
EGIT_REPO_URI="https://github.com/mtytel/helm.git"

case "$PV" in
	"0.8.6-9999")	EGIT_COMMIT="19f86e6b4db83c1c6b143fc27883592ac4e43489" ;;
	"0.8.5-9999")	EGIT_COMMIT="f568b106b08d27238826ef003edd51678656af39" ;;
	"0.8-9999")	EGIT_COMMIT="d71f4075c4ffc5a02645551ffd869a2439abfb47" ;;
	"0.7.1-9999")	EGIT_COMMIT="8546072ebb52924f36e3c4e99460d6fb12cb5f6b" ;;
	"0.7.0-9999")	EGIT_COMMIT="2c14e78110eeaa841dbbe8c11dcbeb161123615a" ;;
	"0.6.6-9999")	EGIT_COMMIT="7eb827f20f2cf85fddf3f54c14ba9f96bd5ceed7" ;;
	"0.6.3-9999")	EGIT_COMMIT="9599422c1bf4d094157512e1f07b07dd66ff0d83" ;;
	"0.6.2-9999")	EGIT_COMMIT="0ea228b2ae32f0e5738c3b31cd448962909e954c" ;;
	"0.6.1-9999")	EGIT_COMMIT="db209280217a17294dea15209d6d31254678af5a" ;;
esac

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND="media-libs/alsa-lib
	media-libs/lv2
	media-sound/jack-audio-connection-kit
	virtual/opengl
	x11-libs/libX11
	x11-libs/libXext"
DEPEND="${RDEPEND}"

DOCS="README.md"

src_prepare() {
	sed -e 's|/usr/lib/|/usr/'$(get_libdir)'/|' -i Makefile || die
	epatch_user
}

src_compile() {
	emake PREFIX="${D}/usr"
}

src_install() {
	default
	make_desktop_entry /usr/bin/helm Helm /usr/share/helm/icons/helm_icon_32_1x.png
}
