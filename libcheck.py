#!/usr/bin/python
# Copyright (c) 2014-2018 Phusion Holding B.V.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#
# libcheck, imported from https://github.com/phusion/holy-build-box
# See https://github.com/phusion/holy-build-box/blob/master/TUTORIAL-7-VERIFYING-PORTABILITY-WITH-LIBCHECK.md
# for documentation.
#

import os, sys, subprocess, re

SYSTEM_LIBRARIES_REGEX = \
	"linux-gate|linux-vdso|libpthread|librt|libdl|libcrypt|libm|libc" + \
	"|ld-linux.*|libutil|libnsl|libgcc_s|libresolv"

if len(sys.argv) <= 1:
	print("Usage: libcheck <FILES>")
	print("Check whether the given executables or shared libraries are linked against non-system libraries.")
	print("")
	print("By default, these libraries are allowed:")
	print("%s" %(SYSTEM_LIBRARIES_REGEX))
	print("")
	print("You can allow more libraries by setting $LIBCHECK_ALLOW, e.g.:")
	print("  env LIBCHECK_ALLOW='libcurl|libcrypto' libcheck /usr/bin/foo")
	sys.exit(1)

BRACKET = re.compile('\\[')

if 'LIBCHECK_ALLOW' in os.environ:
	WHITELIST_REGEX = re.compile('(' + SYSTEM_LIBRARIES_REGEX +
		'|' + os.environ['LIBCHECK_ALLOW'] + ')\\.so')
else:
	WHITELIST_REGEX = re.compile('(' + SYSTEM_LIBRARIES_REGEX + ')\\.so')

INDICATOR_REGEX = re.compile("Shared library:")

error = False

for path in sys.argv[1:]:
	readelf = subprocess.check_output(['readelf', '-d', path], universal_newlines=True).split('\n')
	offenders = []
	for line in readelf:
		line = line.strip()
		if len(line) > 0 and re.search(INDICATOR_REGEX, line) and not re.search(WHITELIST_REGEX, line):
			if re.search(BRACKET, line) is None:
				library = line
			else:
				library = re.split(BRACKET, line, 1)[1]
			library = re.sub(r'\]', '', library)
			offenders.append(library)
			error = True
	if len(offenders) > 0:
		print("%s is linked to non-system libraries: %s" % (path, offenders))

if error:
	sys.exit(1)
