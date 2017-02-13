# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils git-r3

DESCRIPTION="Open source polyphonic software synthesizer with lots of modulation"
HOMEPAGE="http://tytel.org/helm/"
EGIT_REPO_URI="https://github.com/mtytel/helm.git"

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
