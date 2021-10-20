#!/usr/bin/perl -w
#
#--- delete obsolete snapshot archive (snarc) files
#

$snarcdir  = '/data/mta/www/MIRROR/Snap';
$snarcroot = "$snarcdir/snarc.";

while (<$snarcroot*>) {
    if (-M $_ > 3.0) { unlink $_; }
}
