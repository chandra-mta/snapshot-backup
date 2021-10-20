#!/usr/bin/perl

#--------------------------------------------------------------------------------------
#
#   tloger.pl:  write the snapshot to a daily archive file if it has changed
#
#           October 2000: State checking added by TLA
#                    Robert Cameron
#                    October 1999
#
#           December 2000 BDS: add state checking
#                    print new annotated snapshot
#
#       Note: Will not run if RT data is not flowing,
#             to force update, even on old data, use -f option.
#
#       modified by t. isobe (tisobe@cfa.harvard.edu)
#       last update: Oct 29, 2015
#
#--------------------------------------------------------------------------------------

use lib '/data/mta_www/MIRROR/Snap/Scripts/LIB';
use snap;
#
#--- define the working directory for the snapshots
#

my $work_dir     = "/data/mta/www/MIRROR/Snap";
my $exc_dir      = "$work_dir/Exc";
$text_ver        = "/home/mta/Snap/chandra.snapshot";   #--- use this when the file does not exist locally
#
#--- file to write if check comm fails and alert is sent
#
$check_comm_file = "/home/mta/Snap/check_comm_fail_bu"; 
my @ftype        = qw(ACA CCDM EPHIN EPS PCAD SIM-OTG SI TEL EPS-SFMT NORM-SFMT IRU);

my $aos = 0;
@tlfiles = <$exc_dir/chandra*.tl>;

foreach $f (@tlfiles) {
    if (&time_test($f,3)) {
        $aos = 1;
        last;
    }
}

if ($ARGV[0] =~ m/-f/) { $aos=1; }
if (! $aos) {
    use snap_format;
    update_txt("$text_ver");
#
#--- see if we should be aos
#
    check_comm($check_comm_file);
    exit();
}

if (-s $check_comm_file) {
    print MAIL "Colossus-v - data flow resumed.\n";
    close MAIL;
    unlink $check_comm_file;
} 

my %h = get_data($exc_dir, @ftype);
 
use comps;
%h = do_comps(%h);

%h = set_status(%h, get_curr(%h));
#
#--- check state
#
use lib '/home/mta/Snap';

use check_state;
%h = check_state(%h);

use snap_format;
my $snap_text = write_txt(%h);
my $snap_html = write_htm(%h);
#
#--- write out the current snapshot
#
#--- write out the current snapshot

$snapf = $text_ver;
open(SF,">$snapf") or die "Cannot create $snapf\n";
print SF $snap_text;
close SF;

$snapf = "$work_dir/chandra.snapshot";
open(SF,">$snapf") or die "Cannot create $snapf\n";
print SF $snap_text;
close SF;
#
#--- make a static archive
#
$snapf  = "$work_dir/snarc.html";
$snapfa = "$work_dir/Scripts/snarc.tmp";

system("mv $snapf $snapfa");

open(SFA,"<$snapfa") or die "Cannot open to $snapfa\n";
open(SF, ">$snapf")  or die "Cannot open to $snapf\n";

print SF "<html><body bgcolor=\"\#000000\"><pre>\n";
print SF $snap_html;

<SFA>;              #---  skip old header

while (<SFA>) {
    print SF $_;
}
close SFA;
close SF;
#
#--- write the snapshot to a daily archive file if it has changed
#
$date  = sprintf "%4d%3.3d",$y+1900,$yday+1;
$snapf = "$work_dir/snarc.$date";

open(SF,">>$snapf") or die "Cannot append to $snapf\n";
print SF $snap_html;
close SF;

$snapf = "$work_dir/snarc.$date";
open(SF,">>$snapf") or die "Cannot append to $snapf\n";
print SF $snap_html;
close SF;

#$snapf = "$work_dir/snap.wml";
#open(SF,">$snapf") or die "Cannot append to $snapf\n";
#print SF $snap_wap;
#close SF;

