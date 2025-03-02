# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

ACCT_USER_ID="83"
ACCT_USER_GROUPS=( "angie" )
ACCT_USER_HOME="/usr/lib/angie"

acct-user_add_deps

