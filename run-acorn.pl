#!/proj/cm/Release/install.linux64.DS10/ots/bin/perl

#---------------------------------------------------------------------------------
#
#   check that my acorn process is running
#   if not, restart and log the process id
#
#   Robert Cameron
#   April 2000
#
#   modified by t. isobe (tisobe@cfa.harvard.edu)
#
#   last update  Oct 29, 2015   TI
# 
#---------------------------------------------------------------------------------

$uid       = "mta";
$work_dir  = "/data/mta/www/MIRROR/Snap";
$exc_dir   = "$work_dir/Exc";
$pid_file  = "$exc_dir/racorn.pid";
$script_dir= "$work_dir/Scripts";

@acorn     = qw(/home/ascds/DS.release/bin/acorn);
$acorn_exe = (-e $acorn[0])? $acorn[0] : $acorn[1];

$UDP_port  = "11512";           #---- colossus-v

$msids     = "$work_dir/Scripts/chandra-msids.list";
$filesize  = 500;
#
#--- set environment variables for acorn
#
@mta_data  = qw(/home/ascds/DS.release/config/mta/data /data/mta2/pallen/acorn-1.3/groups /home/swolk/acorn/groups);
$ENV{ASCDS_CONFIG_MTA_DATA} = (-e $mta_data[0])? $mta_data[0] : $mta_data[1]; 
#
#--- use custom IPCL dir to get uncalibrated SHLDART, DETART, but
#--- everything else calibrated
#
#@ipcl = qw(/home/ascds/DS.release/config/tp_template/P011 /data/mta/www/MIRROR/Snap/Scripts/P009 /home/ascds/swolk/IPCL/P008 /home/swolk/acorn/ODB);
@ipcl = qw(/data/mta/www/MIRROR/Snap/Scripts/P011 /data/mta/www/MIRROR/Snap/Scripts/P009);

$ENV{IPCL_DIR} = (-e $ipcl[0])? $ipcl[0] : $ipcl[1];
$ENV{LD_LIBRARY_PATH} = '/home/ascds/DS.release/lib:/home/ascds/DS.release/ots/lib:/soft/SYBASE_OSRV15.5/OCS-15_0/lib:/home/ascds/DS.release/otslib:/opt/X11R6/lib:/usr/lib64/alliance/lib:$LD_LIBRARY_PATH';
$ENV{TLM_TEMPLATE_SET_DIR}='/home/ascds/DS.release/config/tp_template/';

chdir $exc_dir or die "Cannot cd to $exc_dir\n";
#
#--- get the PID for the last known acorn process
#
open  (PIDF, "$pid_file") or die "Cannot read PID file $pid_file\n";
while (<PIDF>) { @pinfo = split };
#
#--- get the PID for the currently running acorn process (if any)
#
@p = `/bin/ps auxwww | grep $uid`;
@a = grep /$acorn_exe.+$msids/, @p;
if (!@a) {
    $host=`hostname`;
    chomp $host;
    system("source ~/.ascrc -r release; $acorn_exe -u $UDP_port -C $msids -e $filesize -nv > /dev/null &");
    open  MAIL, "|mailx -s acorn tisobe\@cfa.harvard.edu swolk\@cfa.harvard.edu msobolewska\@cfa.harvard.edu";
    print MAIL  "$host colossus-v acorn dead. restarting. \n\n"; # current version
    close MAIL;
    print "Acorn process not found: restarting\n";
    sleep 3;
}

@p = `/bin/ps auxwww | grep $uid`;
@a = grep /$acorn_exe.+$msids/, @p;
die "Cannot find or restart acorn process\n" if (!@a);

foreach (@a) {
    @f   = split;
    $pid = $f[1];
}
#
#--- compare the actual and expected PIDs. Log any change.
#
if ($pinfo[0] ne $pid) {
    $date = `date`;
    print "Acorn PID mismatch. Putting pid $pid in $pid_file at $date";
    open (PIDF, ">$pid_file") or die "Cannot write PID file $pid_file\n";
    print PIDF "$pid started at $date";
}
