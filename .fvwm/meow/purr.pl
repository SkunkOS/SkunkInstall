#!/usr/local/bin/perl
use strict;
use warnings;
use diagnostics;
use utf8;
# use English;
use Getopt::Long;
#binmode STDOUT, ':encoding(ASCII)';
#binmode STDOUT, ':encoding(ISO-8859-1)';
binmode STDOUT, ':encoding(C)';
# use open ':encoding(UTF-8)';
#use encoding 'euc-tw', STDIN => 'greek';
# binmode(STDOUT, ":ascii");

# use open ":encoding(utf8)";
# use open OUT => ":latin1";

# my $homedir = '/usr/home/stefan';
my $homedir = $ENV {'HOME'};
my $fvwm_userdir = $ENV {'FVWM_USERDIR'};
my $meowdir = $fvwm_userdir . '/meow';

my $configfile = 'meowconfig.conf';
my $meowupdatefile = 'meowupdate.txt';
my $mru_filename = 'mrucache.txt';
my $desktopcachefile = 'desktopcache.txt';
my $categorycachefile = 'categorycache.txt';
my $fmlistfile = 'fmlist.txt';
my $meowlogfile = 'meow.log';
my $purrlogfile = 'purr.log';
my $categoryfile = 'meowcats.conf';
my $langsfile = 'meowint.conf';
my $fextfile = 'allMimeTypes.txt';
my $updatetemplatefile = 'updatetemplate.txt';

my $meowhelper = $meowdir . '/purr.pl';
$mru_filename = $meowdir . '/' . $mru_filename;
$desktopcachefile = $meowdir . '/' . $desktopcachefile;
$categorycachefile = $meowdir . '/' . $categorycachefile;
$fmlistfile = $meowdir . '/' . $fmlistfile;
my $logfilepath = $meowdir . '/' . 'purr.log';

my $mru_maxapps = 10;		# max # of apps
my $mru_maxfiles = 10;		# max # of files
my $mru_maxdirs = 10;		# max # of dirs
my $iconflag = 'no';		# display icons? yes/no
my $showhidden = 'hidden';		# display hidden files/directories? yes/no
my $fs_verbtitle = 'verbose';
my $terminal = 'konsole';
my $notrecent = 'notr';	# flag for show not recent (apps)
my $nohead = 'nohead';

my $actionchar = 'A';
my $appchar = 'P';
my $actionstr = 'A ';
my $appstr = 'P ';

my $debugf;

my $browsewithf = 1;

my $ls_all = 'All';
my $ls_recent = 'Recent';
my $ls_recentapps = '     vvv  Recent Applications  vvv';
my $ls_recent_ = '     vvv  Recent ';
my $ls__files = ' Files  vvv';
my $ls__directories = ' Directories  vvv';
my $ls_recentappcategories = '     vvv  Recent App Categories  vvv';
my $ls_appcats = 'App Cats';
my $ls__apps = ' apps';
my $ls__dirs = ' dirs';
my $ls_dirs = 'Dirs';
my $ls_otherappcategories = '-->  Other app categories';
my $ls_allappcategories = '-->  All app categories';
my $ls_browseallfiles = '-->  Browse All Files';
my $ls_openrecentfile  = 'vvv  Open Recent File  vvv';
my $ls_openrecent_  = 'vvv  Open Recent ';
my $ls_openrecentfiles  = 'vvv  Open Recent Files  vvv';
my $ls_recentfiles  = 'vvv  Recent Files  vvv';
my $ls_browserecentdirs = 'vvv  Browse Recent Dirs  vvv';
my $ls_byappcategories = 'vvv  By App Categories  vvv';
my $ls_bytypeof = 'vvv  By type of  vvv';
my $ls_only_ = '-->  Only ';
my $ls__files2 = ' Files';
my $ls_files = 'Files';
my $ls_mimesc = 'Mimes';
my $ls_text = 'Text';
my $ls_image = 'Image';
my $ls_audio = 'Audio';
my $ls_video = 'Video';
my $ls_mime = 'Mime';
my $ls_extension = 'Extension';
my $ls_hidden = 'hidden';
my $ls_openwith = 'Open With';
my $ls_other_ = 'Other ';
my $ls_browsewith_ = 'Browse With... ';

# MRU menu starter

# logging flags:
#   empty:  no logging
#   *	log all
#   I   log each invocation of $meowhelper
#   a	meow_a_disprecent
# my $log = 'IafCiFdALODBbW';
my $log =   '*';

my $lfh;	# log file handle
my $los;
my $os;

my @filebrowserapps;			# List of apps that can handle inode/directory mimetype
my $showdirs = '';

# there are arrays for each MRU list
# the max length of the MRU list is determined by
# file browser directories display options:
# only, none, last, or just empty string for normal behavior (dirs first)

# one program for various modes:
# mode definition "constants"

# second level app menu	
#	- list of Recent apps
#	- list of links to recently used app categories
#	- link to allapp categories
#old: my $mru_p_mode_appdisplay = "A_DISP";		# display most recent apps
my $mru_p_mode_a_intro = "A_INTRO";	


# 	meow_f_intro
#	- list of Recent apps
#	- list of links to recently used app categories
#	- link to allapp categories
my $mru_p_mode_f_intro = "F_INTRO";	

# embedded and third+ level app menu	

# displays the most recent app list
#	meow_a_disprecent
#	- cat: 'main' | <classid>
#   	- flags: nohead
my $mru_p_mode_a_disprecent = "A_RECENT";		

# display most recent app categories list
# 	meow_a_disprecentcats
#	- cat: 'main' | <classid>
#   	- flags: nohead
my $mru_p_mode_a_disprecentcats = "A_RECENTCATS";	

# displays the most recent file list
#	meow_f_disprecent
#	- cat: 'main' | <classid>
#   	- flags: nohead
my $mru_p_mode_f_disprecent = "F_RECENT";		

# display most recent app categories list
# 	meow_f_disprecentcats
#	- cat: 'main' | <classid>
#   	- flags: nohead
my $mru_p_mode_f_disprecentacats = "F_RECENTACATS";	
#my $mru_p_mode_dirdisplay = "D_DISP";		# display recent directories menu
my $mru_p_mode_d_disprecent = "D_RECENT";
my $mru_p_mode_d_browse = "D_BROWSE";		# browse directory, second and deeper levels
my $mru_p_mode_a_openmenu = "A_OPENMENU";	# open app specific start menu: start, actions, recents
my $mru_p_mode_appdisplayinit = "A_DISPINIT";	# display recent app menu incl. menu tree etc
my $mru_p_mode_a_open = "A_OPEN";		# start app -> update history, launch
my $mru_p_mode_a_browse = "A_BROWSE";		# browse all apps
my $mru_p_mode_filedisplayinit = "F_DISPINIT";	# display recent files menu
my $mru_p_mode_filedisplay = "F_DISP";		# display recent files menu
my $mru_p_mode_dispreccatfiles = "F_DISPRCCT";	# display recent category files menu
my $mru_p_mode_f_mimerecentinit = "F_MIMERCCTINIT";	# display recent category files menu
my $mru_p_mode_f_mimerecent = "F_MIMERCCT";	# display recent category files menu
my $mru_p_mode_f_fextrecentinit = "F_FEXRCCTINIT";	# display recent category files menu
my $mru_p_mode_f_fextrecent = "F_FEXRCCT";	# display recent category files menu
my $mru_p_mode_dirdisplayinit = "D_DISPINIT";	# display recent directories menu
my $mru_p_mode_dirdisplay = "D_DISP";		# display recent directories menu
my $mru_p_mode_d_browseinit = "D_BROWSEINIT";	# first level of directory browse: select between text, image, audio, video and all files
my $mru_p_mode_diropenwith = "D_OPENWITH";	# open dir, usually by a file manager
my $mru_p_mode_f_fileopenwith = "F_OPENWITH";	# display file OpenWith menu
my $mru_p_mode_f_diropenwith = "F_DIROPENWITH";	# display directory DirOpenWith menu
my $mru_p_mode_f_fileopen = "F_OPEN";		# open file using selection in OpenWith menu, launch together with app

my $allfileph = '*';	# placeholder for match all filenames
my $twodph = 0;		# placeholder for two-dimensional hohoa TODO noch viele 0 en ersetzen im code
my $nofextph = '.';	# placeholder for match files with no filename extension

my $mru_p_mode = '';	# mode to work in
my $mru_p_app = '';	# appid if applicable
my $mru_p_act = '';	# action if applicable
#my $mru_p_dir = "";	# directory if applicable (in browse mode)
my $mru_p_file = '';	# file to open with
my $mru_p_cat = '';	# category if any
my $mru_p_flags = '';
my $mru_p_fexts = '';
my $nohdr = 1;
my $verbt = -1;
my $kludge = '';

# FVWM-specific
#my $menuheads = "DestroyMenu recreate $kludge\nAddToMenu $kludge MissingSubmenuFunction menuMeowFunc\n+ DynamicPopDownAction DestroyMenu $kludge\n";
my $catindentst = "-->  ";	# "highlighting" of categories, directories etc



	
GetOptions(
    "mode=s"    	=> \$mru_p_mode,
    "app=s"  		=> \$mru_p_app,
    "action=s"  		=> \$mru_p_act,
#    "dir=s"    		=> \$mru_p_dir,
    "file=s"    	=> \$mru_p_file,
    "cat=s"	    	=> \$mru_p_cat,
    "fexts=s"		=> \$mru_p_fexts,
    "flags=s"		=> \$mru_p_flags,		# all (nicht in main app cat), recent, non-recent, (="other") 
    "kludge=s"    	=> \$kludge
#    "configfile=s" => \$configfile,  
) || wrong_usage();
wrong_usage() if @ARGV;

sub wrong_usage {
    print STDERR "FAIL.\n";
    exit -1;
}

########################################################################
# kludge to work around fvwm problem with $1
# see http://www.fvwmforums.org/phpBB3/viewtopic.php?f=6&t=3075
if ($kludge ne '') {
  my @kargs = split( ';', $kludge);
  foreach my $kla (@kargs) {
    (my $lv, my $rv) = $kla =~ /(.*)=(.*)/;
    if ($lv eq 'mode') {
      $mru_p_mode = $rv;
    } elsif ($lv eq 'app') {
      $mru_p_app = $rv;
    } elsif ($lv eq 'action') {
      $mru_p_act = $rv;
    } elsif ($lv eq 'file') {
      $mru_p_file = unescapepathname( $rv);
    } elsif ($lv eq 'cat') {
      $mru_p_cat = $rv;
    } elsif ($lv eq 'fexts') {
      $mru_p_fexts = $rv;
    } elsif ($lv eq 'flags') {
      $mru_p_flags = $rv;
    }
    # now set a few flag vars to save code redundancy
    $nohdr = index( $mru_p_flags, $nohead) != -1;
    $verbt = index( $mru_p_flags, $fs_verbtitle) != -1;
} }

########################################################################

# base data structure
# %mru {} -> <hash> -> <array>
my %mru;
# App MRU - last n app called (no matter what category!)
# mru { 'mru_lastapps' } -> { "$dummyconst" } > -> [n last called apps]
# App MRU - last n app called per fext
# mru { 'mru_fext_lastapps' } -> { "$fext" } > -> [n last called apps]
# MIME MRU - last n app called per mime main cat
# mru { 'mru_mmcat_lastapps' } -> { "mm$cat" } > -> [n last called apps]
# App MRU - last n app called per app cat
# mru { 'mru_cat_lastapps' } -> { "$cat" } > -> [n last called apps]

# Directory MRU - last n dirs called
# mru { 'mru_lastdirs' } -> { "$dummyconst" } > -> [n last called dirs]
# Directory MRU - last n dirs called per fext
# mru { 'mru_fext_lastdirs' } -> { "$fext" } > -> [n last called dirs]
# Directory MRU - last n dirs in that files called per app cat
# mru { 'mru_cat_lastdirs' } -> { "$cat" } > -> [n last called dirs]
# App MRU - last n dirs in that files called 
# mru { 'mru_app_lastdirs' } -> { "$app" } > -> [n last called dirs]
# MIME MRU - last n dirs in that mime main category called 
# mru { 'mru_mmcat_lastdirs' } -> { "$mmcat" } > -> [n last called dirs]

# File MRU - last n files called
# mru { 'mru_lastfiles' } -> { "$dummyconst" } > -> [n last called files]
# File MRU - last n files called per fext
# mru { 'mru_fext_lastfiles' } -> { "$fext" } > -> [n last called files]
# File MRU - last n files called per app cat
# mru { 'mru_cat_lastfiles' } -> { "$cat" } > -> [n last called files]
# App MRU - last n dirs in that files called per app start
# mru { 'mru_app_lastfiles' } -> { "$app" } > -> [n last called files]
# MIME MRU - last n files in that files called 
# mru { 'mru_mmcat_lastfiles' } -> { "$mmcat" } > -> [n last called files]

# main categories name list
# { <name of main category> }
my @list_cats_main;
# main categories -> subcategories tree hash
# { <name of main category> -> <reference to array of subcategory names> }
my %tree_cats_main_sub;	
# { <(sub)categoryname> -> <string containing their short name>
my %list_cats_textname;
# same as above, but containing the long (descriptive) category text
# { <(sub)categoryname> -> <string containing text description>
my %list_cats_textdesc;
# all categories and their associated apps (both main and subcategories!)
# { <(sub)categoryname> -> <reference to array of apps (their name id field)>
my %tree_cats_apps;
# all apps (their name field) and their associated fields
# { <appname> -> <hash of fields> }
my %list_apps_fields;
# some apps have actions defined.
# Just store these groups with their max. 3 fields (Exec, Name, Icon)
# { <appname> -> <hash of actions> -> <hash of fields} }
my %list_apps_actions;
# hash with the four data mime categories as keys and comma delimited fext list strings as values
my %list_mimefexts;



sub readutffile {
  my $flref = shift;
  my $fname = shift;
  my $fh;
  my $fbuf;
#   open( $fh, '<:encoding(UTF-8)', $fname) or die;   #  "cannot open : $!";
  open( $fh, '<:encoding(UTF-8)', $fname) or die;   #  "cannot open : $!";
  # TODO we cannot assume no file will be smaller than 1 MB. This is no good way
  my $fchars = read( $fh, $fbuf, 1000000);
  die if (not defined $fchars);
  # convert buffer into array of lines
  # get all things between BOF, newlines and EOF that are nonempty and noncomment and make them array entries
  my $s_start = 0;
  my $s_end = 0;
  do {
    $s_end = index( $fbuf, "\n", $s_start);
    if ($s_end > $s_start) {
      # non-empty line
      # get line text
      my $line = substr( $fbuf, $s_start, $s_end - $s_start);
      # skip if comment line
      if (not ($line =~ /\#[^\n]*/)) {
# print "start = '$s_start'   end = '$s_end'  '$line'\n";
	push @$flref, $line;
    } } elsif ($s_end == $s_start) {
      # empty line
    } elsif ($s_end == -1) {
      # no more nl, maybe unterminated text line
      $s_end = length $fbuf;
      if ($s_end > $s_start) {
	my $line = substr( $fbuf, $s_start, $s_end - $s_start);
# print "start = '$s_start'   end = '$s_end'  '$line'\n";
	# skip if comment line
	if (not ($line =~ /\#[^\n]*/)) {
	  push @$flref, $line;
    } } }
    $s_start = $s_end + 1;
  } until ($s_start >= $fchars);
  close $fh;
#foreach (@$flref) {print "$_\n"};
}

sub readutfdir {
  my $dname = shift;
# print "\nreadutfdir '$dname'\n";
  opendir DIR, $dname or die; # "cannot open dir $dname: $!";
  my @dir = readdir DIR;
  closedir DIR;
# foreach (@dir) {print "$_\n"};
  return @dir;
}

#   inserts an item at beginning of list if not yet present in list
#   if already present in list, moves it at beginning and reorders the list accordingly
#	mru_insertitem( array, item, maxsize) 	
sub mru_insertitem {
  my $itemarref = shift;
  my $item = shift;
  my $maxsize = shift;
  my $i = 0;
  my $found = 0;
  my $arrsiz = scalar @$itemarref;
  while ($arrsiz>$i) {
    if (${$itemarref} [$i] eq $item) {
      $found = 1;
      last;
    }
    ++$i;
  }
  if ($found == 1) {
    if ($i == 0) {
      # it's the first elem, nothing to do
      return;
    }
    # move up item 0-(i-1) and then place i at 0
    while ($i>0) {
      --$i;
      ${$itemarref} [$i+1] = ${$itemarref} [$i];
    }
  } else {
    # not found
    $i = $arrsiz;
    if ($i>=$maxsize) { $i = $maxsize -1; }
    while ($i>0) {
      ${$itemarref} [$i] = ${$itemarref} [$i-1];
      --$i;
  } }
  ${$itemarref} [0] = $item;
}

#   if no item present, inserts an item 
#   if already present, replaces old item
#	mru_insertreplaceitem( array, item, maxsize) 	
sub mru_insertreplaceitem {
  my $itemarref = shift;
  my $item = shift;
  my $maxsize = shift;
  my $i = 0;
  my $found = 0;
  my $arrsiz = scalar @$itemarref;
  if ($arrsiz>0) {
    # remove old content
    @{$itemarref} = ();
  }
  ${$itemarref} [0] = $item;
}

#   reads MRU file
#   	mru_read ( filepath)
sub mru_read {
  my $filepath = shift;
  my $item;
  my $mcat;
  my $cat;
  return if (not -f $filepath);
  my @flines = ();
  readutffile( \@flines, $filepath);
  foreach my $fl (@flines) {
    chomp $fl;
    # skip blank lines
    next if ($fl =~ /^(\s)*?$/);
    # check if a group section begins
    if ($fl =~/^\[(.*?)\]$/) {
      # has the line any whitespace?
      if (index($fl,' ')>=0) {
	# three-dimensional
        # <mru_cat_...> <categoryid> 
        ($mcat, $cat) = $fl =~ /^\[(.*?) (.*?)\]$/;
      } else {  
	# two-dimensional
	($mcat) = $fl =~ /^\[(.*?)\]$/;
	$cat = $twodph;
      }
      $item = 0;	# item counter reset at new group
      next;
    }
    $mru {$mcat} {$cat} [$item++] = $fl;
} }

#   writes MRU file
# mru_write ( filepath)
#
sub mru_write {
  my $fp = shift;
  open( my $fh, ">:encoding(UTF-8)", $fp) or die; # "cannot open > $fp: $!";
  # now print into file whatever is cached
  # TODO: maybe remove sort after debugging
  foreach my $m ( sort keys %mru ) {
    foreach my $s ( sort keys %{$mru {$m}}) {
      if ($s eq $twodph) {
	print $fh "[$m]\n";
      } else {
	print $fh "[$m $s]\n";
      }
      foreach (@{${$mru {$m}}{$s}}) {
        print $fh "$_\n";
  } } } 
  close $fh;
}

sub readcategorycache {
  my $filepath = shift;
  my $active;
  return if (not -f $filepath);
  my @flines = ();
  readutffile( \@flines, $filepath);
  foreach my $fl (@flines) {
    chomp ($fl);
    next if ( $fl eq "" );
    if ( $fl =~ /^\[(.*?)\]$/) {
      # [ category ] block start
      ($active) = $fl =~ /^\[(.*?)\]$/;
      next;
    }
    if ($active eq 'maincategories')  {
      (my $cat, my $subcatl) = $fl =~ /^(.*)=(.*)$/;
#      $cat = lc $cat;
      push (@list_cats_main, $cat);
      $tree_cats_main_sub {$cat} = [split (' ', lc $subcatl)];
      # make a hash for a list of all categories (as keys) and arrays of their actual app ids
      # just set empty values in for now, next active pass will load the actual apps
      $tree_cats_apps {$cat} = ();
    } elsif ($active eq 'mimefexts')  {		# XXX Kate bugged?  the arrow on the left does NOT uncover the text of this section!!!!
      (my $cat, my $fexl) = $fl =~ /^(.*)=(.*)$/;
      $list_mimefexts {$cat} = $fexl;
    } elsif ($active eq 'catapps')  {
      (my $cat, my $appl) = $fl =~ /^(.*)=(.*)$/;
      my @ta;
      if (index($appl,' ')>=0) {
	@ta = split (' ', $appl);
      } else {
        @ta = ($appl);
      }
      $tree_cats_apps {$cat} = \@ta;
#      $tree_cats_apps {$cat} = split (' ', $appl);
    } elsif ($active eq 'catindentst')  {
      $catindentst = $fl;
    } elsif ($active eq 'localizedcategorytexts')  {
      (my $cat, my $cattext, my $catdescr) = $fl =~ /^(.*)=(.*):(.*)$/;
      $list_cats_textname {$cat} = $cattext;
      $list_cats_textdesc {$cat} = $catdescr;
} } }

sub readfmlist {
  my @flines = ();
  readutffile( \@flines, $fmlistfile);
  foreach my $fl (@flines) {
    chomp $fl;
    if (substr( $fl, 0, 1) eq 'P') {
#      push @filebrowserapps, substr($fl, 2);
      push @filebrowserapps, $fl;
} } }

sub readdesktopcache { 
  my $filepath = shift;
  my @wds;
  return if (not -f $filepath);
  my @flines = ();
  readutffile( \@flines, $filepath);
  foreach my $fl (@flines) {
    chomp $fl;
    next if ( $fl eq "" );
    if ( $fl =~ /^\[(.*)\]$/) {
      @wds = split( ' ', $1);
      next;
    }
    # now get hash data pairs
    (my $lstr, my $rstr ) = $fl =~ /^([^=]+)=(.*)/;
    # now store value in hash
    if ($wds[0] eq $appchar) {
      ${$list_apps_fields {$wds[1]}} {$lstr} = $rstr;
    } elsif ($wds[0] eq $actionchar) {
      ${${$list_apps_actions { $wds[1] }} { $wds[2] }} { $lstr } = $rstr;
} } }

sub prout {
  my $lf = shift;
  print $os;
  if (($lf eq '*') or (index($log,$lf)>=0) or ($log eq '*')) {
    $lf = '*' if ($lf eq '');
    $os =~ s/^/'$lf'  /gm;
    print $lfh "'$lf'  ============================= start\n$os'$lf'  ============================= end\n";
} }

sub proutlog {
  my $lf = shift;
  if (($lf eq '*') or (index($log,$lf)>=0) or ($log eq '*')) {
    print $lfh "=$lf=  ============================= start\n$los=$lf=  ============================= end\n";
} }

# FVWM menu header
my $menuheads = "DestroyMenu recreate \"$kludge\"\nAddToMenu \"$kludge\" MissingSubmenuFunction menuMeowFunc\n+ DynamicPopDownAction DestroyMenu \"$kludge\"\n";

# displays the most recent app list
#	cat: 'main' | <classid>
#   	flags: nohead
sub meow_a_disprecent {
  $os = $menuheads if (not $nohdr);
#$os .= "+ \"Flags: $mru_p_flags\"\tNop\n" if ($debugf);
  $os .= "+ \"$ls_recentapps\" Nop\n" if ($verbt);
  if (exists $mru {'mru_lastapps'}) {
    # decide whether to show which of the 1. mru_lastapps, 
    # 2. mru_fext_lastapps, mru_fext_lastapps or mru_memcat_lastapps
    # to show
    #
    # handling is fairly common: there is a different mru hash key for the 
    # (currently) four modes
    # the modes are different in this way:
    my $lind;    my $i1;    my $i2;
    # check if we are in "main" category?
    if ($mru_p_cat eq 'main') {
      $lind = 'main';      $i1 = 'mru_lastapps';     $i2 = $twodph;
    } else {
      # all other cats except 'main'
      $lind = $mru_p_cat;  $i1 = 'mru_cat_lastapps'; $i2 = $mru_p_cat;
    }
    # now prepare the recent apps list:
    # print the apps list
    foreach my $appn (@{$mru {$i1}{$i2}}) {
      my $app = substr $appn, 2;
      # is it an app or an action?
      if (substr($appn,0,1) eq 'P') {
	if (exists $list_apps_fields { $app }) {
	  $os .= '+ "' . ${$list_apps_fields { $app }} {'name'} .
	    "\"\tPopup \"mode=$mru_p_mode_a_openmenu;app=$app\"\n";
      } } else {
	# action! do not display other actions!
	(my $actapp, my $action) = $app =~ /(.*) \[(.*)\]/;
	$os .= '+ "' . ${$list_apps_fields { $actapp }} {'name'} . ' ' .
	    ${${$list_apps_actions { $actapp }} {$action}} {'name'} .
	    "\"\tPopup \"mode=$mru_p_mode_a_openmenu;app=$actapp;action=$action;flags=$notrecent\"\n";
  } } }
#   prout('a') if (not $nohdr);
  prout('a');
}  

# displays the most recent app categories list
#	cat: 'main' | <classid>
#   	flags: nohead
sub meow_a_disprecentcats {
  $os = $menuheads if (not $nohdr);
#$os .= "+ \"Flags: $mru_p_flags\"\tNop\n" if ($debugf);
  $os .= "+ \"$ls_recentappcategories\" Nop\n" if ($verbt);
#  $os .= "+ \"BrowseApps Flags: $mru_p_flags\"\tNop\n";
  if (exists $mru {'mru_lastapps'}) {
    # find the app categories with recently used programs
    my @usedcats;
    foreach my $acat (keys %tree_cats_apps) {
      if (exists ${$mru {'mru_cat_lastapps'}} {$acat}) {
	# check if any app is available - don't display category if all of these apps are on mru_lastapps
	my $arec = 0;
	my $atotal = 0;
	foreach my $capp (@{$tree_cats_apps {$acat}}) {
	  ++$atotal;
	  foreach my $lapp (@{${$mru {'mru_cat_lastapps'}} {$acat}}) {
	    if (($appstr . $capp) eq $lapp) {
	      ++$arec;
	      next;
	  } }
	  if ($atotal > $arec) {  
	    push (@usedcats, $acat);
    } } } }
    # sort these categories by text name
    my %ni;
    foreach my $ucat (@usedcats) {
      $ni { $list_cats_textname {$ucat}} = $ucat;
    }
    # finally display this categories list sorted
    foreach my $catt (sort keys %ni) {
#      $os .= "+ \t\"$catindentst$catt\"\tPopup \"mode=$mru_p_mode_a_disprecent;cat=$ni{$catt}\"\n";
#      $os .= "+ \t\"$catindentst$catt\"\tPopup \"mode=$mru_p_mode_appbrowse;cat=$ni{$catt};flags=$notrecent\"\n";
      $os .= "+ \t\"$catindentst$catt\"\tPopup \"mode=$mru_p_mode_a_browse;cat=$ni{$catt};flags=$notrecent\"\n";
    }
    # now offer/print a link to the "other" app categories that are not used recently
    if ($mru_p_cat eq 'main') {
      $os .= "+ \"$ls_otherappcategories\" Popup \"mode=$mru_p_mode_a_browse;cat=$mru_p_cat;flags=$notrecent\"\n" ;
    } else {
      # subcategory: we have to check if the selected category has any app that is not in the main recent apps list
      # is the member count of the last recently used category apps smaller than the total category app #?
      if (scalar  @{$tree_cats_apps{$mru_p_cat}} > scalar  @{$mru {'mru_cat_lastapps'}{$mru_p_cat}}) {
	    $os .= "+ \"\" Nop\n+ \"$ls_other_" . $list_cats_textname {$mru_p_cat} .
	    "$ls__apps\" Popup \"mode=$mru_p_mode_a_browse;cat=$mru_p_cat;flags=$notrecent\"\n";
  } } }
#   prout('A') if (not $nohdr)
  prout('A');
}

# sub anyin( arrayref, str)
# returns 0 or 1
sub anyin {
  my $aref = shift;
  my $str = shift;
  my $isin = 0;
  foreach (@$aref) {
    next if ($_ ne $str);
    $isin = 1;
  }
  return $isin;
}

sub escapepathname {
  my $path = shift;
  # TODO better escaping !!! also escape ';'
  $path =~ s/ /\\_/g;
  return $path;
}

sub unescapepathname {
  my $path = shift;
  # TODO better escaping !!! also escape ';'
  $path =~ s/\\_/ /g;
  return $path;
}

sub meow_a_browse {
  $os = $menuheads if (not $nohdr);
# TODO global notr
  my $notr = index( $mru_p_flags, $notrecent) ne '';
  if ($mru_p_cat eq 'main') {
    foreach my $cat (@list_cats_main) {
      my $kparm = $list_cats_textname { $cat };
      my $kparm2 = "mode=$mru_p_mode_a_browse;cat=$cat";
      $kparm2 .= ";flags=$mru_p_flags";
      my $nonrf = 1;
      if ($notr) {
	# if only showing non-recent main categories, check ...
        if (exists ${$mru {'mru_cat_lastapps'}} {$cat}) {
	  # ...that the checked category is not in recent hash
	  # but if the category is there,
	  # make sure there is at least one non-recent item (program) in it
	  #   if none is found, don't display the category
	  $nonrf = 0;
	  foreach my $catapp (@{$tree_cats_apps { $cat }}) {
	    my $f2 = 0;
	    foreach my $recata (@{${$mru {'mru_cat_lastapps'}} {$cat}}) {
	      if (($appstr . $recata) eq $catapp) {	# TODO ineff
	        $f2=1;
	        last;
 # TODO form  goto
	    } }
	    # if we reach here amd f2 is still 0,
	    # we found a category app that is not in the recent list
	    if ($f2 == 1) {
	      $nonrf=1;
	      last;
 # TODO form  goto
      } } } }
      $os .= "+ \"$catindentst$kparm\"\tPopup $kparm2\n" if ($nonrf==1);
  } } else {
    # show programs in that category
    # to have them sorted, make a hash with the (localized) app names as keys
    # as values take their name ids
    my %ni;
    my @scatlist;
    my $ismaincat = (anyin( \@list_cats_main, $mru_p_cat) ) ? 1	: 0;
    if ($ismaincat == 1) {
      foreach my $mc (@{$tree_cats_main_sub {$mru_p_cat}}) {
	if ($notr) {
          if (exists ${$mru {'mru_cat_lastapps'}} {$mc}) {
	    # check if any app is available - don't display category if all of these apps are on mru_lastapps
	    my $arec = 0;
	    my $atotal = 0;
	    foreach my $capp (@{$tree_cats_apps {$mc}}) {
	      ++$atotal;
	      foreach my $lapp (@{${$mru {'mru_cat_lastapps'}} {$mc}}) {
		if (($appstr . $capp) eq $lapp) {
		  ++$arec;
		  next;
	      } }
	      if ($atotal > $arec) {  
		$ni { $list_cats_textname {$mc}} = $mc;
	    } }
	  } else {
	    $ni { $list_cats_textname {$mc}} = $mc;
	  }
	} else {
	  $ni { $list_cats_textname {$mc}} = $mc;
      } }
      foreach my $mct (sort keys %ni) {
	$os .= "+ \"$catindentst$mct\"\tPopup \"mode=$mru_p_mode_a_browse;cat=$ni{$mct}" .
	(($notr) ? ";flags=$notrecent" : '') . "\"\n";
    } }
    %ni = ();
    if (exists $tree_cats_apps { $mru_p_cat }) {
      foreach my $app (@{$tree_cats_apps { $mru_p_cat }}) {
	if ($notr) {
	  # check for the category app to exist in the recent lists
	  if (exists ${$mru {'mru_cat_lastapps'}} {$mru_p_cat}) {
	    # check if the program is in it
	    my $found = 0;
	    foreach (@{${$mru {'mru_cat_lastapps'}} {$mru_p_cat}}) {
	      if ($_ eq ($appstr . $app)) {
		$found = 1;
		last;
	    } }
	    # skip the app if found
	    next if ($found==1);
	} }
	# now check if the app is in a subcategory/has this field non-empty
	my $issubcat = 0;
	my $sca = (exists ${$list_apps_fields { $app }} {'subcat'} )
	  ? ${$list_apps_fields { $app }} {'subcat'}
	  : '';
	if ($sca ne '') {
	  # check if that subcat has already been added in list
	  if (@scatlist) {
	    if (anyin(\@scatlist, $sca) == 0) {
	      push( @scatlist, $sca);
	      $issubcat = 1;
	  } } else {
	    push( @scatlist, $sca);
	    $issubcat = 1;
	} }
	# store the app for display
	if (($ismaincat == 1) or ($issubcat == 1) or ($sca eq $mru_p_cat)) {
	  $ni {${$list_apps_fields { $app }} {'name'}} = $app;
    } } }
    if (%ni) {
 # TODO     more verbose output depending on option
      foreach my $appt (sort keys %ni) {
	$os .= "+ \"$appt\"\tPopup \"mode=$mru_p_mode_a_openmenu;app=$ni{$appt}\"\n";
    } }
    if (@scatlist) {
      # quick check:
      # when you are in a 2nd level subcat, then @scatlist has 1 member
      # which is same as #mru_p_cat
      if ((scalar @scatlist > 1) or ($scatlist[0] ne $mru_p_cat)) {
 # TODO   more verbose output depending on option
	# get text names and sort
	my %nis;
	foreach (@scatlist) {
	  $nis {$list_cats_textname {$_}} = $_;
	}
	# just a delimiter
	$os .= "+ \"\"\tNop\n";
	foreach my $appct (sort keys %nis) {
	  $os .= "+ \t\"$appct\"\tPopup \"mode=$mru_p_mode_a_browse;cat=$nis{$appct}" .
	  (($notr) ? ";flags=$notrecent" : '') . "\"\n";
  } } } }
  prout('A');
}

sub meow_a_intro {
  $os = $menuheads;
# $os .= "+ \"Flags: $mru_p_flags\"\tNop\n" if ($debugf);
  $mru_p_cat = 'main';
  if (exists $mru {'mru_lastapps'}) {
    $nohdr = 1;
#    $mru_p_flags = ($mru_p_flags eq '') ? $nohead : "$mru_p_flags,$nohead";
# TODO
#     $os .= "+ \"\" Nop\n";
#    if ($verbt) {
#  $os .= ($mru_p_cat eq 'main')
#	? $ls_recentprograms
#	: ($ls_recent_ . $list_cats_textname {$mru_p_cat} . $ls__rograms);
#  $os .= "\" Nop\n";
#      $os .= "+ \"$ls_recentapps\" Nop\n";
#    }

    meow_a_disprecent;
    # now the app list is printed
    # main category, display subcategories
    # draw a distinctive visible marker
    $os .= "+ \"\" Nop\n";
# TODO
#    if ($verbt) {
#  $os .= ($mru_p_cat eq 'main')
#	? $ls_recentprograms
#	: ($ls_recent_ . $list_cats_textname {$mru_p_cat} . $ls__rograms);
#  $os .= "\" Nop\n";
#      $os .= "+ \"$ls_recent_" . $list_cats_textname {$mru_p_cat} . "$ls_applications\"Nop\n";
#      $os .= "+ \"$ls_recentappcategories\" Nop\n";
#    }
    meow_a_disprecentcats;
  } else {
    # only when no recent apps yet offer access to "all" apps -> "original xdg_menu"
    $nohdr = 1;
    meow_a_browse;
  }
#    $os .= "+ \"$ls_allappcategories\" Popup \"mode=$mru_p_mode_a_browse;cat=$mru_p_cat\"\n" ;
#  prout('i');
}

sub meow_f_disprecent {
  my $ind1; my $ind2; my $os2;
  if ($mru_p_cat eq 'main') {
    $ind1 = 'mru_lastfiles';
    $ind2 = $twodph;
  } else {
    $ind1 = 'mru_cat_lastfiles';
    $ind2 = $mru_p_cat;
  }
  if (exists ${$mru {$ind1}}{$ind2}) {
    $os = $menuheads if (not $nohdr);
$os .= "+ \"Flags: $mru_p_flags\"\tNop\n" if ($debugf);
    if ($verbt) {
      $os .= ($mru_p_cat eq 'main')
		? "+ \"$ls_openrecentfiles\" Nop\n" 
		: ($os .= "+ \"$ls_openrecent_" . $list_cats_textname {$mru_p_cat} . "$ls__files\" Nop\n") ;
    }
    foreach my $pat ( @{${$mru {$ind1}}{$ind2}}) {
      # cut off filename base part
      (my $pn, my $fn) = $pat =~ m|^(.*[/\\])([^/\\]+?)$|;
      $pat = escapepathname( $pat);
      $os .= "+ \"$fn\"\tPopup \"mode=$mru_p_mode_f_fileopenwith;file=$pat\"\n";
    } 
#     prout('f') if (not $nohead);
    prout('f');
} }

sub meow_d_disprecent {
  my $ind1; my $ind2; my $os2;
  if ($mru_p_cat eq 'main') {
    $ind1 = 'mru_lastdirs';
    $ind2 = $twodph;
  } else {
    $ind1 = 'mru_cat_lastdirs';
    $ind2 = $mru_p_cat;
  }
  if (exists ${$mru {$ind1}}{$ind2}) {
    $os = $menuheads if (not $nohdr);
$os .= "+ \"Flags: $mru_p_flags\"\tNop\n" if ($debugf);
    if ($verbt) {
      $os .= ($mru_p_cat eq 'main')
		? "+ \"$ls_browserecentdirs\" Nop\n" 
		: ($os .= "+ \"$ls_openrecent_" . $list_cats_textname {$mru_p_cat} . "$ls__dirs\" Nop\n") ;
    }
    foreach my $pat ( @{${$mru {$ind1}}{$ind2}}) {
      # cut off home path part TODO
#      (my $pn, my $fn) = $pat =~ m|^(.*[/\\])([^/\\]+?)$|;
      $pat = escapepathname( $pat);
      $os .= "+ \"$pat\"\tPopup \"mode=$mru_p_mode_d_browse;file=$pat\"\n";
    } 
#    prout('D') if (not $nohead);
    prout('D');
} }

sub meow_d_browse {
  my $flgs = ($mru_p_flags ne '') ? ';flags=' . $mru_p_flags : '';
  if (-d $mru_p_file) {
    $os = $menuheads;
    my $dpath = $mru_p_file;
# print "bro $dpath\n";
    # remove excessive slashes in dir path   TODO clean up
    $dpath =~ s|/+|/|g;
    $dpath =~ s|/$||;
# print "bro '$dpath'\n";
#    my @files = sort readutfdir( $dpath);			# TODO WHATS THE MISTAKE? DOES NOT CALL sub
    my @flis = readutfdir( $dpath);
    my @files = sort @flis;
# print "bleh '$dpath'\n";
    # show hidden files flag
    if (index($mru_p_flags, $showhidden) < 0) {
      @files = grep /^[^.]/, @files;
    }
    # if $fexts has been specified, set up an array with the fexts
    my @fextlist;
    if ($mru_p_fexts ne "") {
      if (index($mru_p_fexts,',')>0) {
	@fextlist = split (',', $mru_p_fexts);
      } else {
	@fextlist = ($mru_p_fexts);
      }
    } else {
      # dummy fextlist
      @fextlist = ($allfileph);
    }
    my $fos = '';
    my $dos = '';
    if ($showdirs ne 'none') {
      if ($browsewithf) {
	$dos .= "+ \"$ls_browsewith_\"\tPopup \"mode=$mru_p_mode_f_diropenwith;file=$dpath\"\n+ \"\" Nop\n";
      }
      foreach (@files) {
	next if $_ eq '.' or $_ eq '..';
	my $fpath = "$dpath/$_";
	if (-d $fpath) {
	  $fpath = escapepathname( $fpath);
	  $dos .= "+ \"$catindentst$_\"\tPopup \"mode=$mru_p_mode_d_browse;file=$fpath" .
		  (($mru_p_fexts ne '') ? ";fexts=$mru_p_fexts" : '' ) . 
		  $flgs .
		  "\"\n";
    } } }
    if ($showdirs ne 'only') {
      foreach my $fil (@files) {
	next if $fil eq '.' or $fil eq '..';
	my $fpath;
	$fpath = "$dpath/$fil";
	if (-f $fpath) {
	  # if $mru_p_fexts is set, check if file matches
	  if ($fextlist[0] ne $allfileph) {
	    # separate file name extension
	    my $filext;
	    if (index($fil,'.')>=0) {
	      ( $filext) = $fil =~ /\.([^.]+)$/;
	    } else {
	      # filext undef if no filename extension present!
	      $filext = '';
	    }
	    my $found = 0;
	    foreach (@fextlist) {
	      if ($_ eq $filext or ($_ eq $nofextph and $filext eq '')) {
		$found = 1;
		last;
	    } }
	    next if ($found == 0);
	  }
	  # file matches, display it
	  $fpath = escapepathname( $fpath);
	  $fos .= "+ \"$fil\"\tPopup \"mode=$mru_p_mode_f_fileopenwith;file=$fpath" .
		  (($mru_p_fexts ne '') ? ";fexts=$mru_p_fexts" : '' ) . 
		  "\"\n";
    } } }
    $os .= $dos if ($showdirs ne 'last' and $showdirs ne 'none');
    $os .= $fos if ($showdirs ne 'only');
    $os .= $dos if ($showdirs eq 'last');
    prout('b');
} }

sub meow_d_browseinit {
  $os = $menuheads;
  my $pat = escapepathname( $mru_p_file);
  my $flgs = ($mru_p_flags ne '') ? (';flags=' . $mru_p_flags) : '';
  $os .=
	"+ \"$ls_all\"\t Popup \"mode=$mru_p_mode_d_browse;fexts=$allfileph;file=$pat$flgs\"\n"
	. "+ \"$ls_text\"\t Popup \"mode=$mru_p_mode_d_browse;fexts=" . $list_mimefexts {'text'} . ";file=$pat$flgs\"\n"
	. "+ \"$ls_image\"\t Popup \"mode=$mru_p_mode_d_browse;fexts=" . $list_mimefexts {'image'} . ";file=$pat$flgs\"\n"
	. "+ \"$ls_audio\"\t Popup \"mode=$mru_p_mode_d_browse;fexts=" . $list_mimefexts {'audio'} . ";file=$pat$flgs\"\n"
	. "+ \"$ls_video\"\t Popup \"mode=$mru_p_mode_d_browse;fexts=" . $list_mimefexts {'video'} . ";file=$pat$flgs\"\n"
  ;
  prout('B');
}

sub meow_f_intro {
  $os = $menuheads;
  my $flgs = ($mru_p_flags ne '') ? ';flags=' . $mru_p_flags : '';
  $os .= "+ \"Flags: $mru_p_flags\"\tNop\n" if ($debugf);
  if (exists ${$mru {'mru_lastfiles'}}{$twodph}) {
    $mru_p_cat = 'main';
    ($os .= "+ \"$ls_recentfiles\" Nop\n") if ($verbt);
    $mru_p_flags = ($mru_p_flags eq '') ? $nohead : "$mru_p_flags,$nohead";
# maybe TODO
#    meow_f_disprecent;
#    meow_f_disprecentacats;
    $os .= "+ \"$ls_files\"\tPopup \"mode=$mru_p_mode_f_disprecent;cat=main\"\n";
    $os .= "+ \"$ls_dirs\"\tPopup \"mode=$mru_p_mode_d_disprecent;cat=main\"\n";
    # offer linking into files of the matching fexts (if already defined)
    
    $os .= "+ \"\" Nop\n";
    ($os .= "+ \"$ls_bytypeof\" Nop\n") if ($verbt);
    if ((exists $mru {'mru_fext_lastfiles'} or exists $mru {'mru_mmcat_lastfiles'}) and $verbt) {
      $os .= "+ \"$ls_mimesc\"\t Nop\n";
    }
    if (exists $mru {'mru_mmcat_lastfiles'}) {
      $os .= "+ \"$ls_mime\"\tPopup \"mode=$mru_p_mode_f_mimerecentinit\"\n";
    }
    if (exists $mru {'mru_fext_lastfiles'}) {
      $os .= "+ \"$ls_extension\"\tPopup \"mode=$mru_p_mode_f_fextrecentinit\"\n";
    }
    # TODO ?
    # offer linking into files of the matching app categories 
#     $os .= "+ \"$ls_appcats\"\tPopup \"mode=$mru_p_mode_f_disprecentacats\"\n";
    $os .= "+ \"\" Nop\n";
  }
  # offer all files
  my $pat = escapepathname( $homedir);
  $os .= "+ \"$ls_browseallfiles\"\tPopup \"mode=$mru_p_mode_d_browseinit;file=$pat$flgs\"\n";
  prout('f');
}

sub meow_f_fextrecent {
  $os = $menuheads;
  $os .= "+ \"$ls_recent_.$mru_p_fexts$ls__directories\"\tNop\n" if ($verbt);
  foreach my $dir (@{${$mru {'mru_fext_lastdirs'}} {$mru_p_fexts}}) {
    $dir = escapepathname( $dir);
    $os .= "+ \"$dir\"\tPopup \"mode=$mru_p_mode_d_browse;file=$dir;fexts=$mru_p_fexts;flags=optfex\"\n";
  }
  $os .= "+ \"\" Nop\n";
  $os .= "+ \"$ls_recent_.$mru_p_fexts$ls__files\"\tNop\n" if ($verbt);
  foreach my $fil (@{${$mru {'mru_fext_lastfiles'}} {$mru_p_fexts}}) {
    $fil = escapepathname( $fil);
    $os .= "+ \"$fil\"\tPopup \"mode=$mru_p_mode_f_fileopenwith;file=$fil\"\n";
  }
  prout('F');
}

sub meow_f_mimerecent {
  $os = $menuheads;
  $os .= "+ \"$ls_recent_.$mru_p_cat$ls__directories\"\tNop\n" if ($verbt);  # TODO localize  
  foreach my $dir (@{${$mru {'mru_mmcat_lastdirs'}} {$mru_p_cat}}) {
    my $dir = escapepathname( $dir);
    $os .= "+ \"$dir\"\tPopup \"mode=$mru_p_mode_d_browse;file=$dir;cat=$mru_p_cat\"\n";
  }
  $os .= "+ \"\" Nop\n";
  $os .= "+ \"$ls_recent_.$mru_p_cat$ls__files\"\tNop\n" if ($verbt);      # TODO localize
  foreach my $fil (@{${$mru {'mru_mmcat_lastfiles'}} {$mru_p_cat}}) {		# TODO localize
    $fil = escapepathname( $fil);
    $os .= "+ \"$fil\"\tPopup \"mode=$mru_p_mode_f_fileopenwith;file=$fil\"\n";
  }
  prout('F');
}

sub meow_f_fextrecentinit {
  $os = $menuheads;
  foreach my $fex ( keys %{$mru {'mru_fext_lastfiles'}}) {
    $os .= "+ \".$fex\"\tPopup \"mode=$mru_p_mode_f_fextrecent;fexts=$fex\"\n";
  }
  prout('i');
}

sub meow_f_mimerecentinit {
  $os = $menuheads if (not $nohdr);
  foreach my $mim ( keys %{$mru {'mru_mmcat_lastfiles'}}) {  
    $os .= "+ \"$mim\"\tPopup \"mode=$mru_p_mode_f_mimerecent;cat=$mim\"\n";    # TODO localize
  }
  prout('i');
}

# MAYBE TODO
# sub meowDisplayRecentCatFiles {
# }

sub meow_a_openmenu {
  $os = $menuheads;
  if ($verbt) {
    $os .= '+ "' . ( (exists ${$list_apps_fields { $mru_p_app }} {'comment'} ) 
	    ? ${$list_apps_fields { $mru_p_app }} {'comment'}
	    : ${$list_apps_fields { $mru_p_app }} {'name'}
      ) . "\"\tTitle\n";
  }
  $os .= '+ "Start <' . ${$list_apps_fields { $mru_p_app }} {'name'}
	  . ">\"\t" . getexecstr( $mru_p_app, "", "" ) . "\n";
  # are Actions there? 
  my $appactions;
  if ( $mru_p_act eq '' and exists $list_apps_actions {$mru_p_app} ) {
    $appactions = $list_apps_actions {$mru_p_app};
    foreach my $act (keys %{$appactions}) {
      my $aname = ${${$appactions}{$act}}{'name'};
      my $aicon = (exists ${${$appactions}{$act}}{'icon'}) ? ${${$appactions}{$act}}{'icon'} : "";
      my $aexec = (exists ${${$appactions}{$act}}{'exec'}) ? ${${$appactions}{$act}}{'exec'} : "";
      if ($iconflag eq 'no') {
        $os .= "+ \"$aname\"\t" . getexecstr( $mru_p_app, $act, "") . "\n";
      } else {
        die "Do not know!";
  } } }
  # related recent files
  if (exists ${$mru {'mru_app_lastfiles'}}{$mru_p_app}) {
    $os .= "+ \"\" Nop\n+ \"$ls_openrecentfile\" Nop\n" if ($verbt);
    foreach my $fil (@{${$mru {'mru_app_lastfiles'}}{$mru_p_app}}) {
      $os .= "+ \"$fil\"\t" . getexecstr( $mru_p_app, '', $fil) . "\n";
    }
    # browse related recent dirs
    # get apps' fexts to browse MAYBE TODO
    my $fex = '*';
    my $flag = '';
    if (exists ${$list_apps_fields {$mru_p_app}} {'mimefexts'}) {
      $fex = ${$list_apps_fields {$mru_p_app}} {'mimefexts'};
      $flag = 'optappfex';
    }
    $os .= "+ \"\"\tNop\n";
    $os .= "+ \"$ls_browserecentdirs\" Nop\n" if ($verbt);
    foreach my $dir (@{${$mru {'mru_app_lastdirs'}}{$mru_p_app}}) {
      $dir = escapepathname( $dir);
      $os .= "+ \"$dir\"\tPopup \"mode=$mru_p_mode_d_browse;file=$dir;fexts=$fex;app=$mru_p_app;flags=$flag\"\n";
  } }
  prout('O');
}

sub meow_f_diropenwith {
  $os = $menuheads;
  my @mrufms = ();		# list #1 
  my @othfms = ();		# list #2
  my %ni = ();
  # produce the MRU list of file managers:
  # walk the last used apps list @filebrowserapps, collect all these of that are in in a 1st helper list
  # then generate a 2nd list, containing those that are not in this mru list
  # display 1st list in the given order, a break (NOP), and then the 2nd list sorted by the human language name
  if (exists $mru {'mru_lastapps'}) {
    foreach my $appr (@{$mru {'mru_lastapps'}{$twodph}}) {
      if (anyin(\@filebrowserapps, $appr)) {
	push @mrufms, $appr;
    } }
    foreach my $appo (@filebrowserapps) {
      if (not anyin(\@mrufms, $appo)) {
	push @othfms, $appo;
    } }
  } else {
    @othfms = @filebrowserapps;
  }
  # sort the non-mru filebrowsers
  foreach (@othfms) {
    $ni {${$list_apps_fields { substr ($_,2) }} {'name'}} = $_;
  }
  my $dir = escapepathname( $mru_p_file);
  if (scalar @mrufms) {
    foreach my $appx (@mrufms) {
      my $appn = ${$list_apps_fields { substr ($appx,2) }} {'name'};
      $os .= "+ \t\"" . $appn . "\"\tExec exec perl $meowhelper --kludge 'mode=$mru_p_mode_f_fileopen;app=" . substr($appx,2) . ";file=$dir'\n";
    }
    $os .= "+ \"\" Nop\n" if (scalar @othfms);
  }
  foreach (sort keys %ni) {
    $os .= "+ \t\"$_\"\tExec exec perl $meowhelper --kludge 'mode=$mru_p_mode_f_fileopen;app=" . substr($ni{$_},2) . ";file=$dir'\n";
  }
  prout('Y');
}

sub meow_f_fileopenwith {
  $os = $menuheads;
  # extract the filename part of path
  (my $fil) = $mru_p_file =~ /\/([^\/]+)$/;
  $os .= " + \"$ls_openwith\"\tTitle\n";
  # first get the filename extension, if any
  (my $filext) = $fil =~ /\.([^.]+)$/;
  # filext undef if no filename extension present!
  $filext = '' if (not defined $filext);
  # the order of shown programs should be:
  # if any, first the most recently used apps that can do this file format 
  # after those, list all remaining apps that can do, these in alphabetically sorting
  my @appslisted = ();
  my $pat = escapepathname( $mru_p_file);
  if (exists $mru {'mru_lastapps'}) {
    # then search the mru apps fextlists if they match the filename extension,
    # print those apps into menu and store them in a temp list for non-inclusion in the next step
    foreach my $appn (@{$mru {'mru_lastapps'}{$twodph}}) {
      my $app = substr $appn, 2;
      # is it an app or an action?
      if (substr($appn,0,1) eq 'P') {
	# this is a program (not an action), so check if it can work that fext/mimetype
	if (exists ${$list_apps_fields { $app }} {'mimefexts'}) {
	  my $appfexts =  ${$list_apps_fields { $app }} {'mimefexts'};
	  # fine, app has fexts defined, check them
	  my $fex = $appfexts =~ /[|,]*($filext)[|,]*/;
	  if ($fex == 1) {
	    # this app does! list it!
	    $os .= ' + "' . ${$list_apps_fields { $app }} {'name'} .
		  "\"\tExec exec perl $meowhelper --kludge 'mode=$mru_p_mode_f_fileopen;app=$app;file=$pat'\n";
	    # store it
	    push (@appslisted, $app);
  } } } } }
  # mark/distinguish the recently used apps using a line
  $os .= "+ \"\" Nop\n" if (scalar @appslisted > 0);
  # now search all apps fextlists, 
  # skip them if they have been listed already
  my @matchapps;
  foreach my $app (keys %list_apps_fields) {
    # does app take files?
    if (exists ${$list_apps_fields { $app }} {'mimefexts'}) {
      my $appfexts =  ${$list_apps_fields { $app }} {'mimefexts'};
      my $fex = $appfexts =~ /[|,]*($filext)[|,]*/;
      if ($fex == 1) {
	# this app matches
	# has it been listed as recent app already?
	my $found = 0;
	foreach (@appslisted) {
	  if ($_ eq $app) {
	    $found = 1;
	    last;
	} }
	# if not, store it in list
	push (@matchapps, $app) if ($found == 0);
  } } }
  # now we probably have a list of matching apps
  # sort them and print into menu
  if (scalar @matchapps > 0) {
    # to have them sorted, make a hash with the (localized) app names as keys
    # as values take their name ids
    my %ni;
    foreach my $app (@matchapps) {
      $ni {${list_apps_fields { $app }} {'name'}} = $app;
    }
    foreach my $appt (sort keys %ni) {
      $os .= "+ \t\"$appt\"\tExec exec perl $meowhelper --kludge 'mode=$mru_p_mode_f_fileopen;app=$ni{$appt};file=$pat'\n";
  } }
  prout('W');
}

# prepare execstring
# sub getexecstr ( $app, $action, $targetfile)
sub getexecstr {
  my $app = shift;
  my $action = shift;
  my $path = shift;
  my $execstr = "Exec exec perl $meowhelper ";
  my $execopts = "mode=$mru_p_mode_a_open;app=$app";
  if ($action ne '') {
    $execopts .= ";action=$action";
    # if action, no file args processing
  } else {
    $execopts .= ";file=$path" if ($path ne '');
  }
  $execstr .= "--kludge '$execopts'";
  return $execstr;
}
  
sub getlaunchstr {
  my $execstr;
  my $targetfile;
  my $app;
  # check if execstr is valid TODO
#  if ($execstr =~ /(%d|%D|%n|%N|%v|%m)/) {
#    die "Illegal Exec option in App \'$app\': $1\n";
#  }
  # check for single file option %fFuU and exchange with actual file
  $execstr =~ s/%f/$targetfile/ if ($execstr =~ /%f/);
  $execstr =~ s/%F/$targetfile/ if ($execstr =~ /%F/);
  $execstr =~ s/%u/$targetfile/ if ($execstr =~ /%u/);
  $execstr =~ s/%U/$targetfile/ if ($execstr =~ /%U/);
  # check for icon option %u
  if ($execstr =~ /%i/) {  # TODO use index()
    # is Icon field present and not empty?
    my $icon = "";
    if ( exists ${$list_apps_fields { $app }} {'icon'} ) {
      $icon = ${$list_apps_fields { $app }} {'icon'};
    }
    if ($icon ne "") {
      # exchange %i with icon file
      $execstr =~ s/%i/--icon $icon/;
  } }
  # check for name (caption) option %u
  if ($execstr =~ /%c/) {
    $execstr =~ s/%c/${$list_apps_fields { $app }}{'name'}/;
  }
  # ignore desktop file option %k
  if ($execstr =~ /%k/) {
    $execstr =~ s/%k//;
  }
  # is "Terminal" set? then different startup method   TODO check this, seems wrong
  if ( exists ${$list_apps_fields { $app }} {'terminal'} ) {
    my $ts = ${$list_apps_fields { $app }} {'terminal'};
    if ($ts =~ /.*=(true|yes)/i) {
      $execstr = $terminal . ' ' . $execstr;
  } }
  # is "Path" set? If so, set CWD according before starting
  if ( exists ${$list_apps_fields { $app }} {'path'} ) {
    # check if path makes sense
    # many path= have empty value
    if (not (${$list_apps_fields { $app }} {'path'} =~ /^\s?$/ )) {
      $execstr = 'cd ' . ${$list_apps_fields { $app }} {'path'} . ';' . $execstr;
  } }
  return $execstr;
}

sub meowDisplayFilesInit {
  $os = $menuheads;
  $os .= "+ \"$ls_recent\"\t Popup \"mode=$mru_p_mode_filedisplay\"\n" .
	"+ \"$ls_all\"\t Popup \"mode=$mru_p_mode_d_browseinit\"\n";
  prout('D');
}

sub meowDisplayDirInit {
  $os = $menuheads;
  $os .=	"+ \"$ls_recent\"\t Popup \"mode=$mru_p_mode_dirdisplay\"\n" .
	"+ \"$ls_all\"\t Popup \"mode=$mru_p_mode_d_browseinit\"\n";
  prout('D');
}

# this sub does the following things:
# register the app being launched
# if a file path is given (file or dir to be opened) then
#    if it is a directory, then
#       -store the directory in the sirectoryhistory
#    if it's a file, then
#	-store the file in the apps' recent list
#       -find out the app main category being started
#	-store the file...
#	   -in the main recent file list and
#	   -in the main category recent file list, and...
#	-store the directory part
#	   -in the main directory history and
#	   -in the main category recent directory list,
# sub launchitem ( app, action, file/dirpath)
sub launchitem {
  my $app = shift;
  my $action = shift;
  my $path = shift;
  my $amcat = '';
  my $ascat = '';
  my $now = sprintf( "%16X", time);
$los = "app=<$app>\taction=<$action>\tpath=<$path>\n";
proutlog('L');
  # register the app being launched in mru
  if ($app ne "") {
    # get app main category
    if (exists ${list_apps_fields {$app}} {'maincat'}) {
      $amcat = ${list_apps_fields {$app}} {'maincat'};
    }
    if (exists ${list_apps_fields {$app}} {'subcat'}) {
      $ascat = ${list_apps_fields {$app}} {'subcat'};
    }
$los = "amcat=<$amcat>\n";
$los .= "ascat=<$ascat>\n";
proutlog('L');
    if ($action ne "") {
      # do action
      my $as = $actionstr . $app . ' [' . $action . ']';
      mru_insertitem( \@{$mru {'mru_lastapps'}{$twodph}}, $as, $mru_maxapps);
      @{$mru {'mru_lastappstime'}{$as}} = ();
      mru_insertitem( \@{$mru {'mru_lastappstime'}{$as}}, $now, $mru_maxapps);
      if ($amcat ne '') {
	mru_insertitem( \@{$mru {'mru_cat_lastapps'}{$amcat}}, $as, $mru_maxapps);
	@{$mru {'mru_lastappstimemcat'}{$as}} = ();
        mru_insertreplaceitem( \@{$mru {'mru_cat_lastappstimemcat'}{$as}}, $now, $mru_maxapps);
      } elsif ($ascat ne '') {
	mru_insertitem( \@{$mru {'mru_cat_lastapps'}{$ascat}}, $as, $mru_maxapps);
	@{$mru {'mru_lastappstimescat'}{$as}} = ();
	mru_insertreplaceitem( \@{$mru {'mru_cat_lastappstimescat'}{$as}}, $now, $mru_maxapps);
      }
    } else {
      # do normal app start
      my $ps = $appstr . $app;
$los .= "ps=<$ps>\n";
proutlog('L');
      mru_insertitem( \@{$mru {'mru_lastapps'}{$twodph}}, $ps, $mru_maxapps);
      @{$mru {'mru_lastappstime'}{$ps}} = ();
      mru_insertitem( \@{$mru {'mru_lastappstime'}{$ps}}, $now, $mru_maxapps);
      if ($amcat ne '') {
	mru_insertitem( \@{$mru {'mru_cat_lastapps'}{$amcat}}, $ps, $mru_maxapps);
	@{$mru {'mru_lastappstimemcat'}{$ps}} = ();
	mru_insertreplaceitem( \@{$mru {'mru_cat_lastappstimemcat'}{$ps}}, $now, $mru_maxapps);
      } elsif ($ascat ne '') {
	mru_insertitem( \@{$mru {'mru_cat_lastapps'}{$ascat}}, $ps, $mru_maxapps);
	@{$mru {'mru_lastappstimescat'}{$ps}} = ();
	mru_insertreplaceitem( \@{$mru {'mru_cat_lastappstimescat'}{$ps}}, $now, $mru_maxapps);
      }
      if ($path ne '') {
	if (-f $path) {
	  # store the file in the app recent file list
	  mru_insertitem( \@{$mru {'mru_app_lastfiles'}{$app}}, $path, $mru_maxfiles);
	  @{$mru {'mru_app_lastfilestime'}{$path}} = ();
	  mru_insertitem( \@{$mru {'mru_app_lastfilestime'}{$path}}, $now, $mru_maxfiles);
	  (my $dpath) = $path =~ /^(.*)\/[^\/]+$/;
	  mru_insertitem( \@{$mru {'mru_app_lastdirs'}{$app}}, $dpath, $mru_maxdirs);
	  @{$mru {'mru_app_lastdirstime'}{$dpath}} = ();
	  mru_insertitem( \@{$mru {'mru_app_lastdirstime'}{$dpath}}, $now, $mru_maxdirs);
	} elsif (-d $path) {
	# store in the app recent dir list
	  mru_insertitem( \@{$mru {'mru_app_lastdirs'}{$app}}, $path, $mru_maxdirs);
	  @{$mru {'mru_app_lastdirstime'}{$path}} = ();
	  mru_insertitem( \@{$mru {'mru_app_lastdirstime'}{$path}}, $now, $mru_maxdirs);
    } } }
    # is it a directory?
    if ($path ne '' and -d $path) {
      # store the directory in the directoryhistory
      mru_insertitem( \@{$mru {'mru_lastdirs'}{$twodph}}, $path, $mru_maxdirs);
      @{$mru {'mru_lastdirstime'}{$path}} = ();
      mru_insertitem( \@{$mru {'mru_lastdirstime'}{$path}}, $now, $mru_maxdirs);
      if ($amcat ne '') {
	# store in the main category recent dir list
	mru_insertitem( \@{$mru {'mru_cat_lastdirs'}{$amcat}}, $path, $mru_maxdirs);
	@{$mru {'mru_cat_lastdirstime'}{$path}} = ();
	mru_insertitem( \@{$mru {'mru_cat_lastdirstime'}{$path}}, $now, $mru_maxdirs);
      }
    } elsif (-f $path) {
      # it's a file
      # store the file in the main recent file list
      mru_insertitem( \@{$mru {'mru_lastfiles'}{$twodph}}, $path, $mru_maxfiles);
      @{$mru {'mru_lastfilestime'}{$path}} = ();
      mru_insertitem( \@{$mru {'mru_lastfilestime'}{$path}}, $now, $mru_maxfiles);
      # store in the main directory history
      if (not exists $mru {'mru_lastdirs'}) {
	@{$mru {'mru_lastdirs'}{$twodph}} = ();
      }
      # separate directory part
      (my $dpath) = $path =~ /^(.*)\/[^\/]+$/;
      mru_insertitem( \@{$mru {'mru_lastdirs'}{$twodph}}, $dpath, $mru_maxdirs);
      @{$mru {'mru_lastdirstime'}{$dpath}} = ();
      mru_insertitem( \@{$mru {'mru_lastdirstime'}{$dpath}}, $now, $mru_maxdirs);
      # find out the app main category being started (if category is defined)
      if ($amcat ne '') {
	# store the file in the main category recent file list
	mru_insertitem( \@{$mru {'mru_cat_lastfiles'}{$amcat}}, $path, $mru_maxfiles);
	@{$mru {'mru_cat_lastfilestime'}{$path}} = ();
	mru_insertitem( \@{$mru {'mru_cat_lastfilestime'}{$path}}, $now, $mru_maxfiles);
	# store in the main category recent dir list
	mru_insertitem( \@{$mru {'mru_cat_lastdirs'}{$amcat}}, $dpath, $mru_maxdirs);
	@{$mru {'mru_cat_lastdirstime'}{$dpath}} = ();
	mru_insertitem( \@{$mru {'mru_cat_lastdirstime'}{$dpath}}, $now, $mru_maxdirs);
      }
      my $filext;
      if ($path =~ /\.([^.]+)$/) {
	($filext) = $path =~ /\.([^.]+)$/;
	# get MIME type
	my $done = 0;
	foreach my $mcat ( ('text', 'image', 'audio', 'video')) {
	  # build temp array from comma-separated mimefext string
	  my @ta;
	  if (index($list_mimefexts {$mcat},',')>=0) {
	    @ta = split (',', $list_mimefexts {$mcat});
	  } else {
	    @ta = ($list_mimefexts {$mcat});
	  }
	  foreach my $mfex (@ta) {
	    if ($mfex eq $filext) {
	      # got mime type!
	      mru_insertitem( \@{$mru {'mru_mmcat_lastfiles'}{$mcat}}, $path, $mru_maxfiles);
	      @{$mru {'mru_mmcat_lastfilestime'}{$path}} = ();
	      mru_insertitem( \@{$mru {'mru_mmcat_lastfilestime'}{$path}}, $now, $mru_maxfiles);
	      mru_insertitem( \@{$mru {'mru_mmcat_lastdirs'}{$mcat}}, $dpath, $mru_maxdirs);
	      @{$mru {'mru_mmcat_lastdirstime'}{$dpath}} = ();
	      mru_insertitem( \@{$mru {'mru_mmcat_lastdirstime'}{$dpath}}, $now, $mru_maxdirs);
	      $done = 1;
	      last;
	  } }
#	  last if ($done == 1);
	  if ($done == 1) {
	    last;
	} }
      } else {
	$filext = $nofextph;
      }
      mru_insertitem( \@{$mru {'mru_fext_lastdirs'}{$filext}}, $dpath, $mru_maxdirs);
      @{$mru {'mru_fext_lastdirstime'}{$dpath}} = ();
      mru_insertitem( \@{$mru {'mru_fext_lastdirstime'}{$dpath}}, $now, $mru_maxdirs);
      mru_insertitem( \@{$mru {'mru_fext_lastfiles'}{$filext}}, $path, $mru_maxfiles);
      @{$mru {'mru_fext_lastfilestime'}{$path}} = ();
      mru_insertitem( \@{$mru {'mru_fext_lastfilestime'}{$path}}, $now, $mru_maxfiles);
      mru_insertitem( \@{$mru {'mru_fext_lastapps'}{$filext}}, $app, $mru_maxapps);
      @{$mru {'mru_fext_lastappstime'}{$app}} = ();
      mru_insertitem( \@{$mru {'mru_fext_lastappstime'}{$app}}, $now, $mru_maxapps);
    }
    mru_write( $mru_filename);
$los = "mrucache written\n";
proutlog('L');
    # now to execute the program, format the exec string
    my $exs = ($action ne '') ? ${${$list_apps_actions {$app}} {$action}} {'exec'}
			    : ${$list_apps_fields {$app}} {'exec'};
    # now look for those %f and %u
    if ($path ne '') {
      # insert file path only if placeholder is present (not always the case with actions!)
      if ($exs =~ /\%[fuFU]/) {
        my $tp = $path;
        $tp =~ s/\ /\\ /g;	# spaces in file names suck ^^
	$exs =~ s/\%[fuFU]/$tp/;
      }
    } else {
      # if no path there %[fuFU], remove the %[fuFU]
      $exs =~ s/%[fuFU]//g;
    }
    # %c caption - replace with the app's short name
    if (index($exs, '%c') >= 0) {
      my $tc = ${$list_apps_fields { $app }} {'name'};
      $exs =~ s/\%c/$tc/;
    }
    # %k The location of the desktop file as either a URI (if for example gotten from the vfolder system) or a local filename or empty if no location is known.
    if (index($exs, '%k') >= 0) {
      # for now empty     TODO implement search routine
      $exs =~ s/\%k//;
    }
    if (index($exs, '%i') >= 0) {
      # The Icon key of the desktop entry expanded as two arguments, first --icon and then the value of the Icon key. Should not expand to any arguments if the Icon key is empty or missing. 
      # for now empty     TODO implement 
      $exs =~ s/\%i//;
    }
    $exs .= ' &';
$los = "System call: =<$exs>\n";
proutlog('L');
    # finally launch
    system($exs);
} }

######################################################### MAIN

sub main {
  if ($log ne '') {
    open( $lfh, ">>:encoding(UTF-8)", $logfilepath) or die; #  "cannot open : $!";
  }
  $los = "Invocation of $meowhelper --kludge '$kludge'\n";
  proutlog('*');
  # check what to do
  if ($mru_p_mode eq $mru_p_mode_a_intro ) { 
	  readcategorycache( $categorycachefile);
	  readdesktopcache( $desktopcachefile);
	  mru_read( $mru_filename);
	  meow_a_intro;
  } elsif ($mru_p_mode eq $mru_p_mode_a_disprecent ) { 
	  readcategorycache( $categorycachefile);
	  readdesktopcache( $desktopcachefile);
	  mru_read( $mru_filename);
	  meow_a_disprecent;
  } elsif ($mru_p_mode eq $mru_p_mode_f_intro ) { 
	  readdesktopcache( $desktopcachefile);
	  readcategorycache( $categorycachefile);
	  mru_read( $mru_filename);
	  meow_f_intro;
  } elsif ($mru_p_mode eq $mru_p_mode_f_disprecent ) { 
	  readdesktopcache( $desktopcachefile);
	  readcategorycache( $categorycachefile);
	  mru_read( $mru_filename);
	  meow_f_disprecent;
# } elsif ($mru_p_mode eq $mru_p_mode_f_disprecentacats ) { 
# 	  readdesktopcache( $desktopcachefile);
# 	  readcategorycache( $categorycachefile);
# 	  mru_read( $mru_filename);
#         meow_f_disprecentacats;
  } elsif ($mru_p_mode eq $mru_p_mode_d_disprecent ) { 
	  readdesktopcache( $desktopcachefile);
	  readcategorycache( $categorycachefile);
	  mru_read( $mru_filename);
	  meow_d_disprecent;
  } elsif ($mru_p_mode eq $mru_p_mode_d_browse ) { 
	  readdesktopcache( $desktopcachefile);
	  readcategorycache( $categorycachefile);
	  meow_d_browse;
  } elsif ($mru_p_mode eq $mru_p_mode_d_browseinit ) { 
	  readdesktopcache( $desktopcachefile);
	  readcategorycache( $categorycachefile);
	  meow_d_browseinit;
  } elsif ($mru_p_mode eq $mru_p_mode_a_openmenu ) { 
	  readcategorycache( $categorycachefile);
	  readdesktopcache( $desktopcachefile);
	  mru_read( $mru_filename);
	  meow_a_openmenu;
  } elsif ($mru_p_mode eq $mru_p_mode_a_browse ) { 
	  readcategorycache( $categorycachefile);
	  readdesktopcache( $desktopcachefile);
	  mru_read( $mru_filename);
	  meow_a_browse;
  } elsif ($mru_p_mode eq $mru_p_mode_a_open ) { 
	  # start app -> update history, launch
	  readcategorycache( $categorycachefile);
	  readdesktopcache( $desktopcachefile);
	  mru_read( $mru_filename);
	  launchitem( $mru_p_app, $mru_p_act, $mru_p_file);
  } elsif ($mru_p_mode eq $mru_p_mode_filedisplayinit ) { 
	  readcategorycache( $categorycachefile);
	  meowDisplayFilesInit();
  } elsif ($mru_p_mode eq $mru_p_mode_dirdisplayinit ) { 
	  readcategorycache( $categorycachefile);
	  meowDisplayDirInit();
  } elsif ($mru_p_mode eq $mru_p_mode_filedisplay ) { 
	  readdesktopcache( $desktopcachefile);
	  readcategorycache( $categorycachefile);
	  mru_read( $mru_filename);
	  meowDisplayRecentFiles();
  } elsif ($mru_p_mode eq $mru_p_mode_dispreccatfiles ) { 
	  readdesktopcache( $desktopcachefile);
	  readcategorycache( $categorycachefile);
	  mru_read( $mru_filename);
	  meowDisplayRecentCatFiles();
  } elsif ($mru_p_mode eq $mru_p_mode_f_fextrecentinit ) { 
	  readdesktopcache( $desktopcachefile);
	  readcategorycache( $categorycachefile);
	  mru_read( $mru_filename);
	  meow_f_fextrecentinit();
  } elsif ($mru_p_mode eq $mru_p_mode_f_fextrecent ) { 
	  readdesktopcache( $desktopcachefile);
	  readcategorycache( $categorycachefile);
	  mru_read( $mru_filename);
	  meow_f_fextrecent();
  } elsif ($mru_p_mode eq $mru_p_mode_f_mimerecentinit ) { 
	  readdesktopcache( $desktopcachefile);
	  readcategorycache( $categorycachefile);
	  mru_read( $mru_filename);
	  meow_f_mimerecentinit();
  } elsif ($mru_p_mode eq $mru_p_mode_f_mimerecent ) { 
	  readdesktopcache( $desktopcachefile);
	  readcategorycache( $categorycachefile);
	  mru_read( $mru_filename);
	  meow_f_mimerecent();
  } elsif ($mru_p_mode eq $mru_p_mode_dirdisplay ) { 
	  readdesktopcache( $desktopcachefile);
	  readcategorycache( $categorycachefile);
	  mru_read( $mru_filename);
	  meowDisplayRecentDirs();
  } elsif ($mru_p_mode eq $mru_p_mode_f_fileopenwith) { 
	  # display OpenWith menu -> stdout>PipeRead
	  readdesktopcache( $desktopcachefile);
	  mru_read( $mru_filename);
	  meow_f_fileopenwith;
  } elsif ($mru_p_mode eq $mru_p_mode_f_fileopen) { 
	  # open file using selected app -> update history, launch
	  readcategorycache( $categorycachefile);
	  readdesktopcache( $desktopcachefile);
	  mru_read( $mru_filename);
	  launchitem( $mru_p_app, $mru_p_act, $mru_p_file);
  } elsif ($mru_p_mode eq $mru_p_mode_f_diropenwith) { 
	  # display OpenWith menu -> stdout>PipeRead
	  readfmlist();
	  readdesktopcache( $desktopcachefile);
	  mru_read( $mru_filename);
	  meow_f_diropenwith();
  } else {
#         die "I don't recognize the name!" ;
  };
}       # end of main()

main ();
# my @flines = ();
# readutffile(\@flines, $configfile);

exit(0);
