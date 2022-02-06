#!/usr/bin/env perl
#use strict;
#use warnings;
#use diagnostics;
use English;
# binmode STDOUT, ':encoding(UTF-8)';
# use open ':encoding(UTF-8)';
# use File::Slurp;
use Getopt::Long;

# configurable things (see sub readconfig and $configfile (meowconfig.conf)
my $mru_maxapps = 10;		# max # of apps
my $mru_maxfiles = 10;		# max # of files
my $mru_maxdirs = 10;		# max # of dirs
my $maxappsinmaincat = 10;	# maximum apps in maincat before moving apps to subcats
my $iconflag = 'no';		# display icons? yes/no
my $showhidden = '';		# display hidden files/directories? yes/no
my $verbosity = 'low';
my $terminal = 'konsole';
my $meowname = 'Meow!';
my @langprio;
my $meowlog;			# logging on if defined/true

# configurable paths 
###############################################################
my $homedir = $ENV {'HOME'};
my $fvwm_userdir = $ENV {'FVWM_USERDIR'};
my $meowdir = $fvwm_userdir . '/meow/';

my $configfile = $meowdir . 'meowconfig.conf';
my $meowupdatefile = $meowdir . 'meowupdate.txt';
my $mru_filename = $meowdir . 'mrucache.txt';
my $desktopcachefile = $meowdir . 'desktopcache.txt';
my $categorycachefile = $meowdir . 'categorycache.txt';
my $fmlistfile = $meowdir . 'fmlist.txt';

my $meowlogfile = $meowdir . 'meow.log';
my $purrlogfile = $meowdir . 'purr.log';
my $categoryfile = $meowdir . 'meowcats.conf';
my $langsfile = $meowdir . 'meowint.conf';
my $fextfile = $meowdir . 'allMimeTypes.txt';
my $updatetemplatefile = $meowdir . 'updatetemplate.txt';

my $meowhelper = $meowdir . 'purr.pl';

# constants
my $version      = "0.00";
my $show_version = undef;

my $errorfh;
my $updatetemplatefh;

my $allfileph = '*';	# placeholder for match all filenames
my $twodph = 0;		# placeholder for two-dimensional hohoa TODO check for remaining '0' in the code
my $nofextph = '.';	# placeholder for match files with no filename extension

# one program for various modes:
# mode definition "constants"

my $mru_p_mode_a_intro = "A_INTRO";	
my $mru_p_mode_f_intro = "F_INTRO";	
my $mru_p_mode_a_disprecent = "A_RECENT";		
my $mru_p_mode_a_disprecentcats = "A_RECENTCATS";	
my $mru_p_mode_f_disprecent = "F_RECENT";		
my $mru_p_mode_f_disprecentacats = "F_RECENTACATS";	
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
my $mru_p_mode_fileopenwith = "F_OPENWITH";	# display file OpenWith menu
my $mru_p_mode_fileopen = "F_OPEN";		# open file using selection in OpenWith menu, launch together with app

# basic data structures
###############################################################

# category tree structures
# main-subcategories tree
# this is the original XDG cat tree defined in the categories config file [XDGcategories]
my %hohoex_old_maincats_subcats;
my %hohoex_old_subcats_maincats;
my %hohoex_old_subcats_subcats;
# this is a lookup for quick check if a category is main or subcat
my %hos_oldcatismainorsub;
my $MAIN = 'm';
my $SUB = 's';
# this is the translation + merging table old XDG -> new Meow
my %hos_maincat_newmaincat;
my %hos_subcat_newsubcat;
# this is the new cat tree defined in the categories config file
my %hohoex_new_maincats_subcats;
my %hohoex_new_subcats_maincats;
# this is a lookup for quick check if a category is main or subcat
my %hos_newcatismainorsub;
# of the above, this is the actually used part of the tree (being populated with apps)
my %hohoex_gen_maincats_subcats;
my %hohoex_gen_subcats_maincats;

# this are the names of the new main cats and subcats. To check if a new cat exists
my %hos_newmaincat;
my %hos_newsubcat;
my @newmaincat_order;

# all categories and their clear-text short names to be actually displayed in the menus
# (not to be confused with their name ids)
# for both main and subcategories
# { <(sub)categoryname> -> <string containing their short name>
#my %list_cats_textname;


# all generated categories and their associated apps (both main and subcategories)
my %hohoex_gen_cats_apps;
my %hohoex_gen_apps_cats;

# separate list of actions, as these are not in categories
my %hohoex_gen_app_actions;

# the original freedesktop categories must be translated to new, more packed ones.
# this is done with this translation lookup: key= original cat name, value: new cat name
# my %hos_maincatxdg_meow;
# my %hos_subcatxdg_meow;

my %hohos_mimes_fexts_ex;
my %hohos_apps_fexts_ex;
my %hohos_mainmimes_fexts_ex;
my %hohohos_apps_fields_lang_s;
my %hohohos_gen_apps_fields_lang_s;		# reduced and modified fields set

# localized data storage
my %hohos_cat_lang_textname;
my %hohos_cat_lang_textdesc;
my %hohos_text_lang;
my %hohos_purrtext_lang;			# localization for actual menu

# Generated localized data:
my %hos_gen_cats_textname;			# Localized category text names
my %hos_gen_cats_textdesc;			# Localized category text descriptions
my %hos_text;					# Localized program text
my %hos_purrtext;				# localization for actual menu

# List of apps that can handle inode/directory mimetype
my @filebrowserapps;

my $nullang = '4N5-Dizg';
my $actionstr = 'A ';
my $appstr = 'P ';

# directories to be searched. List complete and in correct order?
my @searchdirs = (  '/usr/share/kde4/apps',
		    '/usr/share/applications',
#		    '/usr/share/gnome/applications',
		    '/usr/share/applications/kde4',
		    '/usr/local/share/applications',
		    '/usr/local/share/applications/kde4',
		    '/usr/home/stefan/.local',
		    '/usr/home/stefan/.local/share',
		    '/usr/home/stefan/.local/share/applications'
		   );

# /usr/share/mime/application

# /home/stefan/.local/share/recently-used.xbel

my $print_menu = 'no';
# command line options / argv stuff
###############################################################
GetOptions(
    "printmenu|P"    => \$print_menu,
    "version|V"    => \$show_version,
    "help|h|?"     => \&show_help
) || wrong_usage();
wrong_usage() if @ARGV;

# end of variables block
###############################################################

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
# foreach (@$flref) {print "$_\n"};
}

sub readutfdir {
  my $dname = shift;
  opendir DIR, $dname or die; # "cannot open dir $dname: $!";
  my @dir = readdir DIR;
  closedir DIR;
  return @dir;
}

sub readconfig {
  my $activegroup = '';
  my $lstr;  my $rstr;
  my @flines = ();
  readutffile( \@flines, $configfile);
  foreach (@flines) {
    chomp; s/^\s*(.*?)\s*/$1/s;		# remove any whitespace at both ends of the string
    next if (/^(.\s+|)\#/);		# ignore lines with comments 
    next if (/^(\s)*?$/);		# skip blank lines too
    if (/^\[(.*?)\]$/) {		# check if a group section begins
      $activegroup = lc $1;
      next;
    } else {
      # not a group line, so get key/value pairs
      /(.*)=(.*)/;
      $_ = $1;  $rstr = $2;
      s/\s//g;				# avoid errors due to whitespace in left values
      $lstr = lc $_;
      $rstr =~ s/^\s+|\s+$//g;		# trim both ends
      if ($rstr =~ /^'.*'$/) {
	($rstr) = $rstr =~ /^'(.*)'$/;	# if in apostrophs, unescape
      }
      
#print "readconfig: rstr = <$rstr>\n";
    }
    
    if ($activegroup eq "main") {
      if ($lstr eq 'languages') {
	@langprio = (index( $rstr, ',')>0) ? split( ',', lc $rstr) : (lc $rstr);
#print "readconfig: langprio: ", join( ',', @langprio), "\n";
      } elsif ($lstr eq 'maxappsinmaincat') {
	$maxappsinmaincat = $rstr;
      } elsif ($lstr eq 'meowlog') {
	$meowlog = ('yes' eq lc $rstr);
      } elsif ($lstr eq 'homedir') {
	$homedir = $rstr;
      } elsif ($lstr eq 'meowdir') {
	$meowdir = $rstr;
      } elsif ($lstr eq 'updatefile') {
	$meowupdatefile = $rstr;
      } elsif ($lstr eq 'categoryfile') {
	$categoryfile = $rstr;
      } elsif ($lstr eq 'fextfile') {
	$fextfile = $rstr;
      } elsif ($lstr eq 'desktopcachefile') {
	$desktopcachefile = $rstr;
      } elsif ($lstr eq 'categorycachefile') {
	$categorycachefile = $rstr;
      } elsif ($lstr eq 'meowlogfile') {
	$meowlogfile = $rstr;
      } elsif ($lstr eq 'updatetemplatefile') {
	$updatetemplatefile = $rstr;
      } elsif ($lstr eq 'showhidden') {
	$showhidden = $rstr;
      } elsif ($lstr eq 'verbosity') {
	$verbosity = $rstr;
} } } }
    
sub readcategories {
  my $activegroup = '';
  my $lstr;  my $rstr;
  
  my @flines = ();
  readutffile( \@flines, $categoryfile);

  foreach (@flines) {
    chomp; s/^\s+(.*)\s+$/$1/s;		# remove any whitespace at both ends of the string
    next if (/^(.\s+|)\#/);		# ignore lines with comments 
    next if (/^(\s)*?$/);		# skip blank lines too
    if (/^\[(.*?)\]$/) {		# check if a group section begins
      $activegroup = lc $1;
      next;
    } else {
      # not a group line, so get key/value pairs
      /(.*)=(.*)/;
      $_ = $1;  $rstr = $2;
      s/\s//g;				# avoid errors due to whitespace in left values
      $lstr = lc $_;
      $rstr =~ s/^\s+|\s+$//g;		# trim both ends
    }
    
    if ($activegroup eq 'xdgmaincategories') {
      if ($lstr eq 'maincategories') {
        my @cats = split('\s+', lc $rstr);
        foreach my $cat (@cats) {
	  $hos_oldcatismainorsub {$cat} = $MAIN;
    } } } elsif ($activegroup eq "xdgadditionalcategories") {
#      $hohoex_oldallcats_allapps {$lstr} = ();
      $hos_oldcatismainorsub {$lstr} = $SUB;
      my @mcs = (index($rstr, ';')>=0) ? split(';', lc $rstr) : (lc $rstr);
      foreach (@mcs) {
	next if ($_ eq '');
	if (exists $hos_oldcatismainorsub {$_} and $hos_oldcatismainorsub {$_} eq $MAIN) {
	  ${$hohoex_old_maincats_subcats {$_}} {$lstr} = '';
	  ${$hohoex_old_subcats_maincats {$lstr}} {$_} = '';
	} else {
#	  ${$hohoex_old_subcats_maincats {$lstr}} {$_} = '';
	  ${$hohoex_old_subcats_subcats {$lstr}} {$_} = '';
	}
    } } elsif ($activegroup eq 'maincategoriesnew') {
      if ($lstr eq 'newmaincategories') {
        my @cats = split('\s+', lc $rstr);
        foreach my $cat (@cats) {
       	  $hos_newcatismainorsub {$cat} = $MAIN;
    } } } elsif ($activegroup eq 'maincategorymapping') {
      $hos_maincat_newmaincat {$lstr} = lc $rstr;
    } elsif ($activegroup eq "newadditionalcategories") {
      $hos_newcatismainorsub {$lstr} = $SUB;
      # prepare for postprocessing: build the hohoex_new_maincats_subcats and hohoex_new_subcats_maincats after
#      $hohoex_new_subcats_maincats {$lstr} = ();
      # at postprocessing check if hohoex_new_subcats_maincats actually points to a maincat. If not, it's probably a subcat mapping  TODO
#      ${$hohoex_new_subcats_maincats {$lstr}} {$rstr} = '';
#      ${$hohoex_new_maincats_subcats {$_}} {$lstr} = '';
#       $hos_subcat_newsubcat {$lstr} = lc $rstr;
      $hos_newsubcat {$lstr} = lc $rstr;
  } }
  # postprocessing
  foreach my $scat (keys %hos_newsubcat) {
    my $targ = $hos_newsubcat {$scat};
    if ($hos_newcatismainorsub {$targ} eq $MAIN) {
      ${$hohoex_new_maincats_subcats {$targ}} {$scat} = '';
      ${$hohoex_new_subcats_maincats {$scat}} {$targ} = '';
      $hos_subcat_newsubcat {$scat} = $scat;
    } elsif ($hos_newcatismainorsub {$targ} eq $SUB) {
      # merge case, do the according checks
      if ($hos_newcatismainorsub {$hos_newsubcat {$targ}} eq $MAIN) {
# 	${$hohoex_new_maincats_subcats {$targ}} {$scat} = '';
# 	${$hohoex_new_subcats_maincats {$scat}} {$targ} = '';
	$hos_subcat_newsubcat {$scat} = $targ;
      } else {
	print $errorfh "readcategories: Error. Category <$scat> is to be merged into category <$targ>, but that does point to <",
		$hos_newsubcat {$targ}, "> which itself is no main cat.\n";
	die "Error."
      }
    } else {
      print $errorfh "readcategories: Subcategory <$scat> has an error\n";
      die "Error."
    }
  }
  
  # test print the tree into log
  print $errorfh "'nreadcategories: Old menu tree contains ", scalar keys %hohoex_old_maincats_subcats, " main categories\n";
  foreach my $mcat (sort keys %hohoex_old_maincats_subcats) {
    print $errorfh "readcategories:      Old Main category <$mcat> contains ", scalar keys %{$hohoex_old_maincats_subcats {$mcat}}, " subcategories.\n";
    foreach my $scat (sort keys %{$hohoex_old_maincats_subcats {$mcat}}) {
      print $errorfh "readcategories:          Old Subcategory <$scat>, points to ", scalar keys %{$hohoex_old_subcats_maincats {$scat}},
      " main categories <", join( ' and ', keys %{$hohoex_old_subcats_maincats {$scat}}), ">.";
      if (exists $hohoex_old_subcats_subcats {$scat}) {
        print $errorfh " Additionally it associates with subcat <", join( ' and ', keys %{$hohoex_old_subcats_subcats {$scat}}), ">.";
      }
      print $errorfh "\n";
  } } 
  print $errorfh "\nreadcategories: New menu tree contains ", scalar keys %hohoex_new_maincats_subcats, " main categories\n";
  foreach my $mcat (sort keys %hohoex_new_maincats_subcats) {
    print $errorfh "readcategories:      New Main category <$mcat> contains ", scalar keys %{$hohoex_new_maincats_subcats {$mcat}}, " subcategories\n";
    foreach my $scat (sort keys %{$hohoex_new_maincats_subcats {$mcat}}) {
      print $errorfh "readcategories:          New Subcategory <$scat>, points to <", join( ',', keys %{$hohoex_new_subcats_maincats {$scat}}), ">\n";
  } }
  print $errorfh "\nreadcategories: Old-to-New translation table contains:\n";
  print $errorfh "\nreadcategories:       ", scalar keys %hos_maincat_newmaincat, " main categories\n";
  foreach my $mcat (sort keys %hos_maincat_newmaincat) {
    print $errorfh "readcategories:         Old: <$mcat>    New Main category <", $hos_maincat_newmaincat {$mcat}, ">\n";
  }
  print $errorfh "\nreadcategories:       ", scalar keys %hos_subcat_newsubcat, " subcategories\n";
  foreach my $scat (sort keys %hos_subcat_newsubcat) {
    print $errorfh "readcategories:         Old: <$scat>    New Sub category <", $hos_subcat_newsubcat {$scat}, ">\n";
  }
}

sub readlocals {
  my $activegroup = '';
  my $lstr;  my $rstr;
  my @flines = ();
  
  readutffile( \@flines, $langsfile);
  foreach (@flines) {
    chomp; s/^\s+(.*)\s+$/$1/s;		# remove any whitespace at both ends of the string
    next if (/^(.\s+|)\#/);		# ignore lines with comments 
    next if (/^(\s)*?$/);		# skip blank lines too
    if (/^\[(.*?)\]$/) {		# check if a group section begins
      $activegroup = lc $1;
      next;
    } else {
      # not a group line, so get key/value pairs
      /(.*)=(.*)/;
      $_ = $1;  $rstr = $2;
      s/\s//g;				# avoid errors due to whitespace in left values
      $lstr = lc $_;
      $rstr =~ s/^\s+|\s+$//g;		# trim both ends
    }
    if ($activegroup eq "localizedcategorytexts") {
      # separate name id and bracketed language id
      if ($lstr =~ /^\S+\[\S+\]/) {
	(my $catn, my $lang) = $lstr =~ /^(.*)\[(.*)\]/;
	$rstr =~ /^(.*):(.*)$/;
	${$hohos_cat_lang_textname {$catn}} {$lang} = $1;
	${$hohos_cat_lang_textdesc {$catn}} {$lang} = $2;
    } } elsif (lc $activegroup eq "meowinternationlization") {
      if ($lstr =~ /^\S+\[\S+\]/) {
	(my $txi, my $lang) = $lstr =~ /^(.*)\[(.*)\]/;
        if ($rstr =~ /^'.*'$/) {
	  ($rstr) = $rstr =~ /^'(.*)'$/;	# if in apostrophs, unescape
	}
	${$hohos_text_lang {$txi}} {$lang} = $rstr;
    } } elsif (lc $activegroup eq "purrinternationlization") {
      if ($lstr =~ /^\S+\[\S+\]/) {
	(my $txi, my $lang) = $lstr =~ /^(.*)\[(.*)\]/;
        if ($rstr =~ /^'.*'$/) {
	  ($rstr) = $rstr =~ /^'(.*)'$/;	# if in apostrophs, unescape
	}
	${$hohos_purrtext_lang {$txi}} {$lang} = $rstr;
} } } }

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

sub processdesktopfile {
  my $file_path = shift;
  my $objname = shift;
  my $activegroup = '';
#  my $daction;
  my $dapp;
  my @flines = ();
  
  readutffile( \@flines, $file_path);
#print $errorfh "Read desktop object file <$file_path>\n";
  
  foreach my $fl (@flines) {
    chomp;
    $fl =~s/^\s*(.*?)\s*/$1/s;		# remove any whitespace at both ends of the string
    next if ( $fl =~ /^(\#|\/)/);	# ignore lines with comments or beginning with /{path}
    next if ( $fl =~ /^(\s)*?$/);	# skip blank lines too
    if ( $fl =~ /^\[(.*?)\]$/) {	# check if a group section begins
      $activegroup = lc $1;
#print $errorfh "Read desktop object file <$file_path>     activegroup <$activegroup>\n";
      if ($activegroup eq "desktop entry" or $activegroup eq "kde desktop entry") {
#print $errorfh "activegroup <$activegroup>\n";
        $dapp = $appstr . $objname;
      } elsif ( $activegroup =~ /^update ([^\s])\s(.*)$/i ) {
	$objname = $1;
        $activegroup = $2;
      } elsif ( $activegroup =~ /^desktop action ([A-Za-z0-9-]+)/i ) {
        $dapp =  $actionstr . $objname . ' '. $1;
#print "ERGERGERT $dapp\n";
      } else {
	$dapp = undef;
	print $errorfh "Unrecognized group name <$activegroup> in desktop object file <$file_path>\n";
      }
      next;
    }
    # Using [KDE Desktop Entry] instead of [Desktop Entry] as header is deprecated.
    if ($dapp) {
      my $field;  my $lang;
      (my $lstr, my $rstr ) = $fl =~ /^([^=]+)=(.*)/;
      $lstr = lc $lstr;
      $lstr =~ s/\s//g;			# avoid errors due to whitespace on left values
      next if ($rstr eq "");	# ignore empty entries
      # check if this field has brackets, i.e. localizated value
      # if so, remove brackets parts
      if ( $lstr =~ /^\S+\[\S+\]/) {
        ($field, $lang) = $lstr =~/^(.*)\[(.*)\]/;
      } else {
	$field = $lstr;
	$lang = $nullang;
      }
      $hohohos_apps_fields_lang_s {$dapp} {$field} {$lang} = $rstr;
} } }

sub getdesktopfiles {
  my $curpath = shift;
print $errorfh "getdesktopfiles <$curpath>\n";
  
  if (-d $curpath) {
    my @files = readutfdir( $curpath);
    foreach (@files) {
      next if $_ eq '.' or $_ eq '..' or -d ;
      my $file_path = "$curpath/$_";
      $file_path =~ s|/+|/|g;
      if (-f $file_path and ($file_path =~ /.\.(desktop|kdelnk)$/i)) {
	(my $objname) = /(.*).desktop/;
#print "File: '$_'\n";
        processdesktopfile( $file_path, lc $objname);
} } } }

sub getdesktopupdates {
  my $appu = '';
  my @flines = ();
  my $field;  my $lang;
  
  if (-f -f $meowupdatefile) {
    @flines = ();
    readutffile( \@flines, $meowupdatefile);
  } else {
    return;
  }

  foreach my $fl (@flines) {
    # remove any whitespace at both ends of the string
    $fl =~s/^\s*(.*?)\s*/$1/s;
    # ignore lines with comments or beginning with /{path},
    next if ( $fl =~ /^(\#|\/)/);
    # skip blank lines too
    next if ( $fl =~ /^(\s)*?$/);
    # check if a group section begins
    if ( $fl =~ /^\[(.*?)\]$/) {
      $appu = lc $1;
      next;
    }
    next if (not exists $hohohos_apps_fields_lang_s {$appu});
    # now get hash data pairs
    (my $lstr, my $rstr ) = $fl =~ /^([^=]+)=(.*)/;
    $lstr = lc $lstr;
    # avoid errors due to whitespace on left values
    $lstr =~ s/\s//g;
    # check if $lstr has brackets, i.e. localizated value
    # if so, remove brackets parts
    if ( $lstr =~ /^\S+\[\S+\]/) {
      $lstr =~/^(.*)\[(.*)\]/;
      $field = $1;
      $lang = $2;
    } else {
      $field = $lstr;
      $lang = $nullang;
    }
    # empty entries delete fields
    if ($rstr eq "") {
      delete ${${$hohohos_apps_fields_lang_s {$appu}} {$field}} {$lang};
    } else {
      ${${$hohohos_apps_fields_lang_s {$appu}} {$field}} {$lang} = $rstr;
} } }
   
#   -read mimetype/filename extensions list file and update MIME type tree with 
#    the filename extensions of the types present (i.e. defined in the .desktop files)
#  after success, the %tree_mimes_mimesubs HoHoA is populated as follows:
#
#	tree_mimes_mimesubs { <mimemain> }  { mimesub }  [ fexts ] 
# example:                     image          jpeg         jpg, jpeg
# 
sub readmimefexts {
  my @flines = ();
  
  readutffile( \@flines, $fextfile );
  foreach my $fl (@flines) {
    chomp $fl;
    # remove any whitespace at both ends of the string
    $fl =~ s/^\s*(.*?)\s*/$1/s;   # TODO fehler?
    # ignore lines with comments or beginning with /
    next if ( $fl =~ /^(\#|\/)/);
    # skip blank lines too
    next if ( $fl =~ /^(\s)*?$/);
    $fl = lc $fl;
    # extract mimetype and fext(s)
    (my $mimet, my $dummy, my $fexts) = ( $fl =~ /(.*):(\s+|)\[(.*)\]/ );
    $fexts =~ s/\s//g;		# remove blanks
    next if ($fexts eq "");
#print "readmimefexts:   mimet <$mimet>   fexts <$fexts>\n";
    my @fextarr;
    if (index( $fexts, ',') >= 0) {
      # multiple, can use split
      @fextarr = split( ',', $fexts);
    } else {
      # one only, create arr manually
      @fextarr = ( $fexts );
    }
    (my $mimemain) = $mimet =~ /^(.*)\//;
#    my $mainflag = ($mimemain eq 'text' or $mimemain eq 'image' or $mimemain eq 'audio' or $mimemain eq 'video')
    my $mainflag = (($mimemain eq 'text') or ($mimemain eq 'image') or ($mimemain eq 'audio') or ($mimemain eq 'video'))
		    ? 1 : 0;
    for my $fex (@fextarr) {
      next if ($fex eq '');
      ${hohos_mimes_fexts_ex {$mimet}} {$fex} = '';
#print "readmimefexts:                     stored mimet <$mimet>   fex <$fex>\n";
#      ${${hohos_mainmimes_fexts_ex {$mimemain}} {$fex}} = '' if ($mainflag==1);
      if ($mainflag==1) {
	${${hohos_mainmimes_fexts_ex {$mimemain}} {$fex}} = '';
#	print "readmimefexts:                     STORED:mimemain <$mimemain>   fex <$fex>\n";
      }
} } } 

sub printmimefexts {
  foreach my $mime (keys %hohos_mimes_fexts_ex) {
    foreach my $fex (keys %{$hohos_mimes_fexts_ex {$mime}}) {
      print "Mimetype <$mime> = <$fex>\n"
} } }  

# add the fext(s) of the given mimetype to another mime class
# (used for collecting all correct mimefexts for the main 4 mimecategories)
# sub addmimefex($app, $thismime, $mimemain) {
sub addmimefex {
  my $thismime = shift;  my $mimemain = shift;
  
  my @fextarr = (exists $hohos_mimes_fexts_ex {$thismime})
	      ? (keys %{$hohos_mimes_fexts_ex {$thismime}}) : ();
  # look if it is already in the %list_mainmimes_fexts
  foreach my $af (@fextarr) {
      ${$hohos_mainmimes_fexts_ex {$mimemain}} {$af} = '';
#print "addmimefex:   thismime <$thismime>   registered as mimemain <$mimemain> fex <$af>\n";
} }

# add the fext(s) of the given mimetype to the 'mimefexts' field of the app object
sub addappmimefex {
  my $thismime = shift;  my $app = shift; 
  
  my @fextarr = (exists $hohos_mimes_fexts_ex {$thismime})
	      ? (keys %{$hohos_mimes_fexts_ex {$thismime}}) : ();
  foreach my $af (@fextarr) {
    ${$hohos_apps_fexts_ex {$app}} {$af} = '';
#print "addappmimefex:   app <$app>   thismime <$thismime>   registered as fex <$af>\n";
} }

  
  # now some postprocessing must be done because of a conceptual shortcoming of the freedesktop spec
  # problem is that we have a mime category "application".
  # But: this category comprises file formats of all other mime categories!
  # And we do not want to browse application files, but text, image, audio and video.
  # Thus we must do some dirty tricks to add the application mimetypes correctly to the actual categories.
  # To achieve this, we utilize the application main and subcategories to associate with the four basic file categories.
  # There are some special cases, however.
  # Ambiguosities: 
  #	database, publishing: usually/primarily text, but can contain other media too
  #	recorder and tuner: no safe way to differentiate. Ignore for now.
  #	printing: can be text and graphics. however, there are few cases of files generated, so just ignore
  # an useful category that I'd like would be archiving/compression as this is really neither of the basic categories.
  # So just keep them with text for now.
  #
  # thus we do a lookup like this: 
  #   walk all {basic data category} [appcategory]
  #     for each of them read all application mimetype fields
  #       for each mimetype get the fexts
  #         add the fexts to the basic data category fexts stored in $list_mainmimes_fexts { }
  # after this the four data type fext lists are completed with the application mimetypes

sub updateapplicationmimefexts {
  my %mappcats = (
	  text => [ 'WordProcessor', 'IDE', 'Languages', 'Shell', 'Documentation',
		    'ConsoleOnly', 'Email', 'WebDevelopment', 'Chat', 'Database',
		    'Dictionary', 'Development', 'Publishing', 'Calculator', 
		    'Finance', 'Translation', 'InstantMessaging','ProjectManagement',
		    'TextEditor', 'IRCClient', 'Spreadsheet', 'ContactManagement',
		    'News', 'TextTools', 'Java', 
		    'WebBrowser', 'Office',
#		    'Compression', 'Archiving', 'DiscBurning',,
		    ],
	  image => ['Art', 'Scanning', '3DGraphics', 'Photography', 'Maps', 'Construction',
 		    'Graphics', 'DataVisualization', 'Presentation', 'ImageProcessing', 
		    'VectorGraphics', 'OCR', 'Chart', 'RasterGraphics', 'FlowChart',
		    '2DGraphics', 'Building' ],
	  audio => ['Audio', 'Sequencer', 'Midi', 'Music', 'Telephony', 'TelephonyTools',
		    'HamRadio', 'Mixer' ],
	  video => ['Video', 'TV', 'AudioVideoEditing', 'VideoConference', 'AudioVideo']
	);
	
  my $appambig;
  my $apprealmimecat;

  # now the actual processing: walk all apps
  foreach my $app (keys %hohohos_apps_fields_lang_s) {
    next if (not exists ${$hohohos_apps_fields_lang_s {$app}} {'mimetype'});
    # Catch potential ambiguities, problems and errors by verifying that an app does not 
    # advertise to more than one of these application-mimetype categories
    if (not exists ${$hohohos_apps_fields_lang_s {$app}} {'categories'}) {
      print $errorfh "updateapplicationmimefexts: 'Categories' field missing in <$app> .desktop file.\n";
      $appambig = 1;
    } else {
      my $ts = ${${$hohohos_apps_fields_lang_s {$app}} {'categories'}} {$nullang};
  #print $errorfh "App <$app>   categories <$ts>\n";    
  #    my @acats = (index($ts,';')>=0) ? split( /;/, lc $ts) : ($ts);
      my @acats;
      if (index($ts,';')>=0) {
	@acats = split( /;/, lc $ts);
      } else {
	@acats = ($ts);
      }
      my %appisinmimecats_ex;
      foreach my $acat (@acats) {
  #print $errorfh "App <$app>   acat <$acat>\n";    
	# find what mappcat this acat belongs to
	foreach my $mcat (keys %mappcats) {
  #print $errorfh "App <$app>   MIMECAT <$mcat>\n";    
	  foreach my $cat (@{$mappcats {$mcat}}) {
  # print $errorfh "cat <$cat>   MIMECAT <$mcat>\n";    
	    if (lc $cat eq $acat) {
	      $appisinmimecats_ex {$mcat} = ''; 
      } } } }
      # is there more than one association to the 4 mime cats?
      $appambig = ((scalar keys %appisinmimecats_ex) != 1) ? 1 : 0;
  #    my $apprealmimecat = @{keys %appisinmimecats}[+0] if ($appambig==0);
      if ($appambig==0) {
	my @ta = keys %appisinmimecats_ex;
	$apprealmimecat = $ta[+0];
  #print $errorfh "App <$app>   OK apprealmimecat <$apprealmimecat>\n";    
      } else {
  #print $errorfh "App <$app>   AMBIGUOUS appisinmimecats <", join( ', ', keys %appisinmimecats_ex), ">\n";    
    } }
    # now walk through the mimetypes of the app
    my $appmimes = lc ${${$hohohos_apps_fields_lang_s {$app}} {'mimetype'}} {$nullang};
    next if ($appmimes eq "");
#print $errorfh "App <$app>   appmimes <$appmimes>\n";    
    my @ma = (index($appmimes,';')>=0) ? split( /;/, $appmimes) : ($appmimes);
    my @appfexts;
    foreach my $thismime (@ma) {
      addappmimefex($thismime, $app);
      (my $mimemain, my $mimesub) = $thismime =~ /(.*)\/(.*)/;
      if ($mimemain eq 'application') {
	# problem if app is ambiguous
	if ($appambig == 0) {
	  # no ambiguities, 
	  if ($apprealmimecat eq 'text') {
	    addmimefex($thismime, $apprealmimecat);
print $errorfh "updateapplicationmimefexts: App <$app>   registered <$thismime> as a text mime\n";    
} } } } } }
    
# this function searches all apps for the inode/directory mimetype
# this mimetype indicates that the "file object" is actually a directory
# all file managers support this mimetype
# the generated list will be used in the "Browse With ..." popups
sub getfilebrowsers {
  foreach my $app (keys %hohohos_apps_fields_lang_s) {
    next if (not exists ${${$hohohos_apps_fields_lang_s {$app}} {'mimetype'}} {$nullang});
    if (index(lc ${${$hohohos_apps_fields_lang_s {$app}} {'mimetype'}} {$nullang}, 'inode/directory') >= 0) {
      # found a file manager
      # register it only if it is a visible app item, i.e no OnlyShowIn or NoDisplay
      # TODO check is done very dirty, make better
      if ( not ( (exists ${${$hohohos_apps_fields_lang_s {$app}} {'onlyshowin'}} {$nullang}) or
	   (exists ${${$hohohos_apps_fields_lang_s {$app}} {'nodisplay'}} {$nullang}) )) {
	push @filebrowserapps, $app;
} } } }

sub registerfilemanagers {
  my $app = shift;
  return if (not exists (${$hohohos_apps_fields_lang_s {$app}} {'mimetype'}) );
  return if (not exists ${${$hohohos_apps_fields_lang_s {$app}} {'mimetype'}} {$nullang});
  if (index(lc ${${$hohohos_apps_fields_lang_s {$app}} {'mimetype'}} {$nullang}, 'inode/directory') >= 0) {
    push @filebrowserapps, $app;
    print $errorfh "registerfilemanagers:   App <$app> registered as file manager.\n";
} } 

sub setappfextsfield {
  foreach my $app (keys %hohohos_apps_fields_lang_s) {
    next if (not exists $hohos_apps_fexts_ex {$app});
    my $fs;  my @fsa;
# scalar on keys forbidden now.
# so we need to copy keys to a temp array and then count its members.
my @temparr =   keys %{$hohos_apps_fexts_ex {$app}};
    
#    if ((scalar keys $hohos_apps_fexts_ex {$app}) > 1) {
#    if ((scalar @(keys $hohos_apps_fexts_ex {$app})) > 1) {
    if ((scalar @temparr) > 1) {
#      $fs = join( ',', keys $hohos_apps_fexts_ex {$app});
      $fs = join( ',', @temparr);
    } else {
#      @fsa = keys $hohos_apps_fexts_ex {$app};
      @fsa = @temparr;
      $fs = $fsa[0];
    }
    ${${$hohohos_apps_fields_lang_s {$app}} { 'mimefexts' }} {$nullang} = $fs;
#print "setappfextsfield:   app <$app>   mimefexts <$fs>\n";
} }

sub mergehiddenappfexts {
  my %hohoex_executable_apps;
  foreach my $app (keys %hohohos_apps_fields_lang_s) {
    if (exists ${$hohohos_apps_fields_lang_s {$app}} {'exec'}) {
      (my $prg) = ${${$hohohos_apps_fields_lang_s {$app}} {'exec'}} {$nullang} =~ /^([^\s]+)/;
#      ${${$hohoex_executable_apps {$prg}} {$app}} = '' if ($prg ne '');
      if ($prg ne '') {
	${${$hohoex_executable_apps {$prg}} {$app}} = '';
#	print $errorfh "mergehiddenappfexts: App <$app> uses Executable <$prg>\n";
      }
  } }
  foreach my $exe (keys %hohoex_executable_apps) {
    if ((scalar keys %{$hohoex_executable_apps {$exe}}) > 1) {
      # this exe is used in multiple .desktop files. Examine this.
      print $errorfh "mergehiddenappfexts: Executable <$exe> is used in these .desktop files: ", 
			join( ',', keys %{$hohoex_executable_apps {$exe}}), "\n";
      # Find out if there is one app being executable and all others 'NoDisplay',
      # or being actions, as this seems the typical case
      my @d;   my @nd;
      foreach my $exapp (keys %{$hohoex_executable_apps {$exe}}) {
        if ( (substr( $exapp, 0, 2) eq $actionstr) or 
            (exists ${$hohohos_apps_fields_lang_s {$exapp}} {'nodisplay'} and
	    lc ${${$hohohos_apps_fields_lang_s {$exapp}} {'nodisplay'}} {$nullang} eq 'true')) {
	  push @nd, $exapp;
	} else {
	  push @d, $exapp;
      } }
      if (scalar @d == 1) {
	# our typical case: 1 visible .desktop app and all other ones handling 
	# extra mimetypes while not displayed in menu
	# thus we merge all the mime types of the apps to the visible ones
	print $errorfh "mergehiddenappfexts: Merged the mimetypes to displayed app <$d[0]>\n";
	foreach my $ndapp (@nd) {
	print $errorfh "mergehiddenappfexts:                From non-displayed app <$ndapp>\n";
	  foreach my $fex (keys %{$hohos_apps_fexts_ex {$ndapp}}) {
	    ${$hohos_apps_fexts_ex {$d[0]}} {$fex} = '';
	    print $errorfh "mergehiddenappfexts:                        Extension <$fex>\n";
      } } } else {
	print $errorfh "mergehiddenappfexts: Warning: No merge because of multiple displayed apps <",
			join( ',', @d), ">\n";
} } } }      
  
sub addcat {
  my $catarref = shift;
  my $cat = shift;

  if (scalar @{$catarref} > 0) {
    my $alreadyregd = 0;
    foreach (@{$catarref}) {
      if ($_ eq $cat) {
	$alreadyregd = 1;
	last;
    } }
    if ($alreadyregd == 0) {
      push @{$catarref}, $cat;
#      print $errorfh "addcat:                         ADDED new category <$cat> as new category (1)\n";
  } } else {
    push @{$catarref}, $cat;
#    print $errorfh "addcat:               ADDED new category <$cat> as new category (1)\n";
} }

# this also checks whether .desktop objects are being included/displayed at all
sub makenewcategories {
  # walk all apps and set up their new categories
  foreach my $app (keys %hohohos_apps_fields_lang_s) {
    if (not exists ${hohohos_apps_fields_lang_s {$app}} {'categories'}) {
      print $errorfh "makenewcategories:   App <$app> IGNORED. No 'categories' field.\n";
      next;
    }
    if (isrunnable($app)==0) {
      print $errorfh "makenewcategories:   App <$app> IGNORED. Runnable check failed.\n";
      next;
    }
    my $cats = lc ${${hohohos_apps_fields_lang_s {$app}} {'categories'}} {$nullang};
#    print $errorfh "makenewcategories: App <$app> has this 'categories' field: <$cats>\n";
    $cats =~ s/\s//g;
    $cats =~ s/^;//;
    $cats =~ s/;$//;
    my @cata = (index($cats,';')>0) ? split(';', $cats) : ($cats);
    my @omc = ();   my @mc = ();   my @osc = ();   my @sc = ();
    foreach my $xcat (@cata) {
      next if ($xcat eq '');				# ignore empty strings caused by excess semicola
#    print $errorfh "makenewcategories:               Processing category: <$cat>\n";
      # translate cat name to new
      my $cat = '';
      my $catis;
      if (exists $hos_maincat_newmaincat {$xcat}) {
	$cat = $hos_maincat_newmaincat {$xcat};
	$catis = $MAIN;
      } elsif (exists $hos_subcat_newsubcat {$xcat}) {
	$cat = $hos_subcat_newsubcat {$xcat};
	$catis = $SUB;
      } else {
#	print $errorfh "makenewcategories:   App <$app>: Unknown category <$xcat> ignored.\n";
        next;
      }
      if ($cat ne '') {
	if ($catis eq $MAIN) {
	  # it is an old main category. Merge it automatically.
#	  print $errorfh "makenewcategories:   Pass: App <$app>, original cat <$xcat>, added to main cat <$cat>\n";
	  addcat( \@mc, $cat);
	  # also store the old main cat(s) if applicable, for suggesting the correct subcats in case there is no subcat
	  addcat( \@omc, $xcat);
	} elsif ($catis eq $SUB) {
#	  print $errorfh "makenewcategories:   Pass: App <$app>, original cat <$xcat>, added to subcat <$cat>\n";
	  addcat( \@sc, $cat);
	  addcat( \@osc, $cat);
    } } }
    # now we should have the valid main cats and subcats in @mc and @sc respective
    # attempt to resolve most common conflicts with some hard coded decisions:
    if ((scalar @sc) >= 1) {
      # the viever case: many vievers register in a random number of media categories.
      # Solution: Remove all subcategories except 'viewer'.
      if (anyin(\@sc, 'viewer')==1) {
	@sc = ('viewer');
	# Make all viewers 'office'.
	@mc = ('office');
      } elsif (anyin(\@sc, 'vectorgraphics')==1) {
	@sc = ('vectorgraphics');
	@mc = ('multimedia');
      } elsif (anyin(\@sc, '2dgraphics')==1) {
	@sc = ('rastergraphics');
	@mc = ('multimedia');
      } elsif (anyin(\@sc, 'email')==1) {
	@sc = ('email');
	@mc = ('network');
      } elsif (anyin(\@sc, 'discburning')==1) {
	@sc = ('discburning');
	@mc = ('multimedia');
    } } 
    if ((scalar @mc) > 1) {
      # the network case: many network apps register in 'utility' category too. Let 'network' take precedence.
      if (anyin(\@mc, 'network')==1) {
	@mc = ('network');
      } elsif ((scalar @mc) == 2 and (anyin(\@mc, 'office')==1) and (anyin(\@mc, 'utility')==1)) {
	# frequent case: clocks, time managers etc advertise in both these cats.
	# Let's put them to 'utility' as they are no essential office stuff.
	@mc = ('utility');
    } }
    if ((scalar @mc) > 1 or (scalar @sc) > 1) {
      print $errorfh "makenewcategories:          CONFLICT WARNING: App <$app> has this 'categories' field: <$cats>\n";
      print $errorfh "makenewcategories:                            It registered in ", scalar @mc, " main and in ",
		      scalar @sc, " subcategories.\n";
      print $errorfh "makenewcategories:                            These are <", join( ',', @mc), '> and <', join( ',', @sc), "> respective\n";
      if ((scalar @sc) > 1) {
	@sc = ($sc[0]);
	print $errorfh "makenewcategories:                          Using only subcategory <$sc[0]> now.\n";
	if (defined $updatetemplatefh) {
	  print $updatetemplatefh "[$app]\n# Multiple, conflicting subcategories: <",
			join( ' ', @osc), ">. Please remove all but one of them.\n";
	  print $updatetemplatefh "Categories=", ${${hohohos_apps_fields_lang_s {$app}} {'categories'}} {$nullang}, "\n";
      } }
      if ((scalar @mc) > 1) {
	@mc = ($mc[0]);
	print $errorfh "makenewcategories:            Using only main category <$mc[0]> now.\n";
	if (defined $updatetemplatefh) {
	  print $updatetemplatefh "[$app]\n# Multiple, conflicting main categories: <",
			join( ' ', @omc), ">. Please remove all but one of them.\n";
	  print $updatetemplatefh "Categories=", ${${hohohos_apps_fields_lang_s {$app}} {'categories'}} {$nullang}, "\n";
    } } }
#     if (((scalar @sc) == 0) and ((scalar @mc) == 0)) {
#       print $errorfh "makenewcategories:   App <$app> HAS NO CATEGORIES??.\n";
#     }
    if ((scalar @sc) == 0) {
      print $errorfh "makenewcategories:          NO SUBCAT WARNING:  App <$app> has no sub category ! ! !\n";
#       if (defined $updatetemplatefh) {
#      if (defined $updatetemplatefh and scalar @mc > 0) {
      if (defined $updatetemplatefh and scalar @omc > 0) {
	print $updatetemplatefh "[$app]\n# Subcategory field missing. Main cats given are <", join( ' ', @omc),
		    ">. Please add *one* of these subcategories: <";
	# get the stored old maincats and collect the subcats of them
	my %hoex_subcs;
	foreach my $omainc (@omc) {
	  foreach (keys %{$hohoex_old_maincats_subcats {$omainc}}) {
	    $hoex_subcs {$_} = '';
	} }
	print $updatetemplatefh join( ' ', keys %hoex_subcs), ">\n";
	print $updatetemplatefh "Categories=", ${${hohohos_apps_fields_lang_s {$app}} {'categories'}} {$nullang}, "\n";
    } }
    if ((scalar @sc) > 0) {
      ${${$hohohos_apps_fields_lang_s { $app }} {'subcat'}} {$nullang} = $sc[0];
      ${$hohoex_gen_cats_apps {$sc[0]}} {$app} = '';
      ${$hohoex_gen_apps_cats {$app} {$sc[0]}} = '';
      registerfilemanagers( $app);
      print $errorfh "makenewcategories:   App <$app> registered to new subcategory <$sc[0]>.\n";
    } elsif ((scalar @mc) > 0) {
      ${${$hohohos_apps_fields_lang_s { $app }} {'maincat'}} {$nullang} = $mc[0];
      ${$hohoex_gen_cats_apps {$mc[0]}} {$app} = '';
      ${$hohoex_gen_apps_cats {$app} {$mc[0]}} = '';
      registerfilemanagers( $app);
      print $errorfh "makenewcategories:   App <$app> registered to new main category <$mc[0]>.\n";
    } 
} }  
  
sub buildnewcattree {
  foreach my $mcat (keys %hohoex_new_maincats_subcats) {
    foreach my $scat (keys %{$hohoex_new_maincats_subcats {$mcat}}) {
      if (exists $hohoex_gen_cats_apps {$scat}) {
	${$hohoex_gen_maincats_subcats {$mcat}} {$scat} = '';
	${$hohoex_gen_subcats_maincats {$scat}} {$mcat} = '';
  } } }
  print $errorfh "buildnewcattree: Generated menu tree contains ", scalar keys %hohoex_gen_maincats_subcats, " main categories\n";
  foreach my $mcat (sort keys %hohoex_gen_maincats_subcats) {
    print $errorfh "buildnewcattree:      Generated Main category <$mcat> contains ", scalar keys %{$hohoex_gen_cats_apps {$mcat}},
			" apps and ", scalar keys %{$hohoex_gen_maincats_subcats {$mcat}}, " subcategories\n";
    foreach my $sapp (sort keys %{$hohoex_gen_cats_apps {$mcat}}) {
      print $errorfh "buildnewcattree:         $sapp\n";
    }
			
    foreach my $scat (sort keys %{$hohoex_gen_maincats_subcats {$mcat}}) {
      print $errorfh "buildnewcattree:          Generated Subcategory <$scat> contains ", scalar keys %{$hohoex_gen_cats_apps {$scat}},
			" apps and points to main cat <", join( ',', keys %{$hohoex_gen_subcats_maincats {$scat}}), ">\n";
      foreach my $sapp (sort keys %{$hohoex_gen_cats_apps {$scat}}) {
	print $errorfh "buildnewcattree:         $sapp\n";
      }

} } }

sub localizelocals {
#print " localizelocals: \n";
  foreach my $idiom (@langprio) {
#print " localizelocals: idiom: $idiom\n";
    foreach my $tx (keys %hohos_cat_lang_textname) {
      if (exists ${$hohos_cat_lang_textname {$tx}} {$idiom}) {
        $hos_gen_cats_textname {$tx} = ${$hohos_cat_lang_textname {$tx}} {$idiom};
    } }

    foreach my $tx (keys %hohos_cat_lang_textdesc) {
      if (exists ${$hohos_cat_lang_textdesc {$tx}} {$idiom}) {
        $hos_gen_cats_textdesc {$tx} = ${$hohos_cat_lang_textdesc {$tx}} {$idiom};
#print " localizelocals: hos_gen_cats_textdesc ($tx) = hohos_cat_lang_textdesc ($tx) ($idiom) ===> ", ${$hohos_cat_lang_textdesc {$tx}} {$idiom}, "\n";
    } }
    foreach my $tx (keys %hohos_text_lang) {
      if (exists ${$hohos_text_lang {$tx}} {$idiom}) {
        $hos_text {$tx} = ${$hohos_text_lang {$tx}} {$idiom};
#print " localizelocals: hos_text ($tx) = hohos_text_lang ($tx) ($idiom) ===> ", $hos_text {$tx}, "\n";
    } }
    foreach my $tx (keys %hohos_purrtext_lang) {
      if (exists ${$hohos_purrtext_lang {$tx}} {$idiom}) {
        $hos_purrtext {$tx} = ${$hohos_purrtext_lang {$tx}} {$idiom};
#print " localizelocals: hos_text ($tx) = hohos_text_lang ($tx) ($idiom) ===> ", $hos_purrtext {$tx}, "\n";
} } } }

sub localizeappdata {
  foreach my $idiom (@langprio) {
    foreach my $app (keys %hohohos_apps_fields_lang_s) {
      foreach my $field ( keys %{$hohohos_apps_fields_lang_s {$app}}) {
	if (exists ${${$hohohos_apps_fields_lang_s {$app}} {$field}} {$idiom}) {
	  ${${$hohohos_apps_fields_lang_s {$app}} {$field}} {$nullang} = 
		    ${${$hohohos_apps_fields_lang_s {$app}} {$field}} {$idiom};
#	  print "                 lang: <$lang> = <", ${${$hohohos_apps_fields_lang_s {$app}} {$field}} {$lang}, ">\n";
} } } } }
  
# bool isrunnable ( appnameid ) returns if app is runnable (ShowOnly... etc)
sub isrunnable {
  my $app = shift;
 
  if (exists ${$hohohos_apps_fields_lang_s { $app }} {'nodisplay'}) {

    # TODO bug related to filelight
    if (not exists (${${$hohohos_apps_fields_lang_s { $app }} {'nodisplay'}} {$nullang})) {
      # TODO this happens but shouldn't. It's a bug and the cause needs to be fixed.
      print $errorfh "isrunnable:          App <$app> SOME BUGG.\n";
      return 0;
    }
    
    if (lc ${${$hohohos_apps_fields_lang_s { $app }} {'nodisplay'}} {$nullang} eq 'true') {
      print $errorfh "isrunnable:          App <$app> NoDisplay is true.\n";
      return 0;
  } }
  if ( exists ${$hohohos_apps_fields_lang_s { $app }} {'hidden'}) {
    if (lc ${${$hohohos_apps_fields_lang_s { $app }} {'hidden'}} {$nullang} eq 'true') {
      print $errorfh "isrunnable:          App <$app> Hidden app.\n";
      return 0;
  } }
  if ( exists ${$hohohos_apps_fields_lang_s { $app }} {'onlyshowin'}) {
    # TODO  get DE id and verify
    # TODO incomplete... might be allowed to show if some DE are installed
#    TODO bug whats wrong with this: print $errorfh "isrunnable:          App <$app> OnlyShowIn " . ${$hohohos_apps_fields_lang_s { $app }} {'onlyshowin'} . ".\n";
    print $errorfh "isrunnable:          App <$app> OnlyShowIn entry found.\n";
    return 0;
  }
# TODO  tryexec including path - make a sub for that!
#   if ( exists ${$hohohos_apps_fields_lang_s { $app }} {'tryexec'}) {
#     return 0 if (lc ${${$hohohos_apps_fields_lang_s { $app }} {'tryexec'}} {$nullang} eq 'true');
#   }
  # check if execstr is valid
  if ( exists ${$hohohos_apps_fields_lang_s { $app }} {'exec'} ) {
    my $es = ${${$hohohos_apps_fields_lang_s { $app }} {'exec'}} {$nullang};
    if ($es =~ /(%d|%D|%n|%N|%v|%m)/) {
      print $errorfh "isrunnable:          App <$app> Forbidden parameters in ExecStr.\n";
      return 0;					# TODO check regexp
    }
  } else {
    print $errorfh "isrunnable:          App <$app> ExecStr missing.\n";
    return 0;
  }
  # nothing found against the program
  return 1;
}



# prepare execstring
# sub getexecstr ( $app, $action, $targetfile)
# sub getexecstr {
#   my $app = shift;
#   my $action = shift;
#   my $targetfile = shift;
#   
#   
#   my $execstr = $meowhelper . " --mode \'A_OPEN\' --app \'" . $app . "\'";
#   if ($action ne "") {
#     $execstr .= ' --action \'' . $action . '\'';
#   }
# #  $execstr = '"' . $execstr . '"';
#   $execstr = 'Exec ' . $execstr;
#   return $execstr;
#   
#   
#   # TODO   abgleichen mit meowhelper
# #  my $execstr = ${$list_apps_fields { $app }} {'exec'};
# #  $execstr = my $foption; 
# #print "getexecstr1: \'$execstr\'\n";
#   # check if execstr is valid
#   if ($execstr =~ /(%d|%D|%n|%N|%v|%m)/) {
#     die "Illegal Exec option in App \'$app\': $1\n";
#   }
#   # check for single file option %fFuU and exchange with actual file
#   $execstr =~ s/%f/$targetfile/ if ($execstr =~ /%f/);
#   $execstr =~ s/%F/$targetfile/ if ($execstr =~ /%F/);
#   $execstr =~ s/%u/$targetfile/ if ($execstr =~ /%u/);
#   $execstr =~ s/%U/$targetfile/ if ($execstr =~ /%U/);
#   # check for icon option %u
#   if ($execstr =~ /%i/) {
#     # is Icon field present and not empty?
#     my $icon = "";
#     if ( exists ${$list_apps_fields { $app }} {'icon'} ) {
#       $icon = ${$list_apps_fields { $app }} {'icon'};
#     }
#     if ($icon ne "") {
#       # exchange %i with icon file
#       $execstr =~ s/%i/--icon $icon/;
#     }
#   }
#   # check for name (caption) option %u
#   if ($execstr =~ /%c/) {
#     $execstr =~ s/%c/${$list_apps_fields { $app }}{'name'}/;
#   }
#   # ignore desktop file option %k
#   if ($execstr =~ /%k/) {
#     $execstr =~ s/%k//;
#   }
#   # is "Terminal" set? then different startup method
#   if ( exists ${$list_apps_fields { $app }} {'terminal'} ) {
#     my $ts = ${$list_apps_fields { $app }} {'terminal'};
#     if ($ts =~ /.*=(true|yes)/i) {
#       $execstr = $terminal . ' ' . $execstr;
#     }
#   }
#   # is "Path" set? If so, set CWD according before starting
#   my $cwd = "~";
#   if ( exists ${$list_apps_fields { $app }} {'path'} ) {
#     # check if path makes sense
#     # many path= have empty value
#     if (not (${$list_apps_fields { $app }} {'path'} =~ /^\s?$/ )) {
#       $execstr = 'cd ' . ${$list_apps_fields { $app }} {'path'} . ';' . $execstr;
#     }
#   }
#   return $execstr;
# }

sub builddesktopactions { 
  foreach my $app (keys %hohohos_apps_fields_lang_s) {
    if (substr( $app, 0, 2) eq $actionstr) {
      $app =~ /A (\S+) (\S+)/;
      $hohoex_gen_app_actions {$1} {$2} = $app;
#print "BTHYHTRHR $app\n";
    }
  }

}
# build FVWM menu
sub buildFVWMmenu {
  print "AddToMenu menuRoot MissingSubmenuFunction menuMeowFunc\n";
  print '+ "', $hos_text {'meow'}, "\"\tTitle\n";
  print '+ "', $hos_text {'apps'}, "\"\tPopup \"mode=$mru_p_mode_a_intro" .
	    (($verbosity eq 'high') ? ';flags=verbose' : '') . "\"\n";
  print '+ "', $hos_text {'files'}, "\"\tPopup \"mode=$mru_p_mode_f_intro";
  my $fopts = '';
  if ($verbosity eq 'high') {
    $fopts = 'verbose';
  }
  if ($showhidden eq 'yes') {
    $fopts .= (($fopts eq '') ? '' : ',') . 'hidden';
  }
  if ($fopts ne '') {
    print ';flags=' . $fopts 
  }
  #  print '+ "', $hos_text {'dirs'}, "\"\tPopup \"mode=$mru_p_mode_dirdisplay\"\n";
  print "\"\n+ \"\"\tNop\n";
  print '+ "', $hos_text {'system'}, "\"\tPopup menuSystem\n\n";
  print "AddToFunc menuMeowFunc\n";
  print " + I PipeRead \"perl $meowhelper --kludge \'\$0\'\"\n\n";
} 

sub writecategorycache { 
  open( my $fh, ">:encoding(UTF-8)", $categorycachefile)
  or die "cannot open > $categorycachefile: $!";
  
  print $fh "[maincategories]\n";
  foreach (keys %hohoex_gen_maincats_subcats) {
    print $fh "$_=", join(' ', keys %{$hohoex_gen_maincats_subcats {$_}}), "\n";
  }
  print $fh "[mimefexts]\n";
  foreach (keys %hohos_mainmimes_fexts_ex) {
    if ($_ eq 'text') {
      print $fh "$_=$nofextph,", join(',', keys %{$hohos_mainmimes_fexts_ex {$_}}), "\n";
    } else {
      print $fh "$_=", join(',', keys %{$hohos_mainmimes_fexts_ex {$_}}), "\n";
  } }
  print $fh "all=*\n";
  print $fh "[catapps]\n";
  foreach my $appc (sort keys %hohoex_gen_cats_apps) {
    my @ta = sort keys %{$hohoex_gen_cats_apps {$appc}};
    my @nta;
    foreach (@ta) {
      push @nta, substr( $_,2);
    }
    print $fh "$appc=", join (' ', @nta), "\n";
  }
  print $fh "[localizedcategorytexts]\n";
  foreach (keys %hos_gen_cats_textname) {
    print $fh "$_=", $hos_gen_cats_textname{$_}, ':', $hos_gen_cats_textdesc{$_}, "\n";
  } 
  close $fh;
}

sub writedesktopcache { 
  open( my $fh, ">:encoding(UTF-8)", $desktopcachefile)
  or die "cannot open > $desktopcachefile: $!";

  foreach my $app (keys %hohoex_gen_apps_cats) {
    print $fh "[$app]\n";
    print $fh 'name=', ${${$hohohos_apps_fields_lang_s {$app}} {'name'}} {$nullang}, "\n";
    if (exists ${$hohohos_apps_fields_lang_s {$app}} {'comment'}) {
      print $fh 'comment=', ${${$hohohos_apps_fields_lang_s {$app}} {'comment'}} {$nullang}, "\n";
    }
    if (exists ${$hohohos_apps_fields_lang_s {$app}} {'icon'}) {
      print $fh 'icon=', ${${$hohohos_apps_fields_lang_s {$app}} {'icon'}} {$nullang}, "\n";
    }
    if (exists ${$hohohos_apps_fields_lang_s {$app}} {'path'}) {
      if (${${$hohohos_apps_fields_lang_s {$app}} {'path'}} {$nullang} ne "") {
        print $fh 'path=', ${${$hohohos_apps_fields_lang_s {$app}} {'path'}} {$nullang}, "\n";
    } }
    if (exists ${$hohohos_apps_fields_lang_s {$app}} {'exec'}) {
      print $fh 'exec=';
      # is "Terminal" set? then different startup method
      if ( exists ${$hohohos_apps_fields_lang_s {$app}} {'terminal'}) {
        if (${${$hohohos_apps_fields_lang_s {$app}} {'terminal'}} {$nullang} =~ /.*=(true|yes)/i) {
          print $fh "$terminal ";
      } }
      print $fh ${${$hohohos_apps_fields_lang_s {$app}} {'exec'}} {$nullang}, "\n";
    }
    if (exists ${$hohohos_apps_fields_lang_s {$app}} {'mimefexts'}) {
        print $fh 'mimefexts=', ${${$hohohos_apps_fields_lang_s {$app}} {'mimefexts'}} {$nullang}, "\n";
    }
    if (exists ${$hohohos_apps_fields_lang_s {$app}} {'maincat'}) {
        print $fh 'maincat=', ${${$hohohos_apps_fields_lang_s {$app}} {'maincat'}} {$nullang}, "\n";
    }
    if (exists ${$hohohos_apps_fields_lang_s {$app}} {'subcat'}) {
        print $fh 'subcat=', ${${$hohohos_apps_fields_lang_s {$app}} {'subcat'}} {$nullang}, "\n";
  } }
  foreach my $actapp (keys %hohoex_gen_app_actions) {
    foreach my $appaction (keys %{$hohoex_gen_app_actions {$actapp}}) {
      my $astr = "$actionstr$actapp $appaction";
      print $fh "[$astr]\n";
      if (exists ${$hohohos_apps_fields_lang_s {$astr}} {'name'}) {
        print $fh 'name=', ${${$hohohos_apps_fields_lang_s {$astr}} {'name'}} {$nullang}, "\n";
      }
      if (exists ${$hohohos_apps_fields_lang_s {$astr}} {'icon'}) {
        print $fh 'icon=', ${${$hohohos_apps_fields_lang_s {$astr}} {'icon'}} {$nullang}, "\n";
      }
      if (exists ${$hohohos_apps_fields_lang_s {$astr}} {'exec'}) {
        print $fh 'exec=', ${${$hohohos_apps_fields_lang_s {$astr}} {'exec'}} {$nullang}, "\n";
  } } } 
  close $fh;
}

sub writefilemanagerlist {
  open( my $fh, ">", $fmlistfile)
    or die "cannot open > $fmlistfile: $!";
  if (scalar @filebrowserapps) {
    foreach (@filebrowserapps) {
      print $fh "$_\n";
  } } 
  close $fh;
}

sub printcatapps {
  print "printcatapps\n";
# TODO  scalar on keys forbidden :(
my @temparr = keys %hohoex_gen_maincats_subcats;
  foreach my $cat (@temparr) {
    print "  Category: $cat ===========\n";
my @temparr2 = keys %{$hohoex_gen_maincats_subcats {$cat}};
    
    foreach my $app ( sort @temparr2) {
      print "  Category: $cat\t\tApp: $app \n";
} } }

sub printmimetree {
  print "printmimetree: \n";
  foreach my $mainmime (sort keys %hohos_mainmimes_fexts_ex ) {
#    print "  main: $mainmime\n";
    foreach my $submime (sort keys %{$hohos_mainmimes_fexts_ex {$mainmime}}) {
      print "  $mainmime\/$submime\n";
} } }
  
sub printappdata2 {
  print "printappdata:\n";
  foreach my $app (keys %hohohos_apps_fields_lang_s) {
    print "App: $app\n";
    foreach my $field ( keys %{$hohohos_apps_fields_lang_s {$app}}) {
      print "        Field: <$field>\n";
      foreach my $lang ( keys %{${$hohohos_apps_fields_lang_s {$app}} {$field}}) {
	print "                 lang: <$lang> = <", ${${$hohohos_apps_fields_lang_s {$app}} {$field}} {$lang}, ">\n";
} } } }
  
sub printappdata {
  print "printappdata:\n";
  foreach my $app (keys %hohohos_apps_fields_lang_s) {
    print "App: $app\n";
    foreach my $field ( keys %{$hohohos_apps_fields_lang_s {$app}}) {
      if (exists ${${$hohohos_apps_fields_lang_s {$app}} {$field}} {$nullang}) {
	print "        Field: <$field> = <", ${${$hohohos_apps_fields_lang_s {$app}} {$field}} {$nullang}, ">\n";
      } else {
	print "        Field: <$field>   NOT IN DEFAULT LANGUAGE??\n";
} } } }

sub printcattree {
  print "printcattree: \n";
  print "  \@list_cats_main element number: ", scalar keys %hohoex_gen_maincats_subcats, "\n";
  foreach my $cmain (keys %hohoex_gen_maincats_subcats) {
    print "\n  Main category <", $cmain, "> has ", scalar keys %{$hohoex_gen_maincats_subcats { $cmain }}, " elements:\n";
    foreach my $csub (sort keys %{$hohoex_gen_maincats_subcats { $cmain }}) {
      print "\n      Sub category <", $csub, "> has ", scalar keys %{${$hohoex_gen_maincats_subcats { $cmain }} {$csub}}, " elements:\n";
} } }

sub printcatnames {
  print "printcatnames: \n";
  print "  Total number of categories: ", scalar keys %hos_gen_cats_textname, "\n";
  foreach my $cat (keys %hos_gen_cats_textname) {
    my $nameshort = exists $hos_gen_cats_textname { $cat } ? $hos_gen_cats_textname { $cat } : "UNDEF";
    my $namelong = exists $hos_gen_cats_textdesc { $cat } ? $hos_gen_cats_textdesc { $cat } : "UNDEF";
    print "  Category ID: ", $cat, "   Menu Text: ", $nameshort, "   Long name: ", 
	    $namelong, "\n";
} }

# now the actual program init
###############################################################
sub progmain {
  open( $errorfh, ">", $meowlogfile)
      or die "cannot open > $meowlogfile: $!";
      
  readconfig;
  if (-e $updatetemplatefile) {
    open( $updatetemplatefh, ">", $updatetemplatefile)
      or die "cannot open > $updatetemplatefile: $!";
  }
  readcategories;
  foreach (@searchdirs) { getdesktopfiles( $_ ); }
  getdesktopupdates;
  readmimefexts;
  updateapplicationmimefexts;
  # handle modular apps using multiple .desktop files with the hidden keyword 
  # to integrate non-default file-type-handlers. Ie Okular, LibreOffice and others.
  mergehiddenappfexts;
#  getfilebrowsers;
  setappfextsfield;
  makenewcategories;
  buildnewcattree;
  readlocals;
  localizelocals;
  localizeappdata;
# printmimefexts;
# printappdata;
  builddesktopactions;
  buildFVWMmenu if ($print_menu ne 'no');
  writecategorycache;
  writedesktopcache;
  writefilemanagerlist;

#  printappdata();
#  printcattree ();
#  printcatapps();
#  printcatnames ();
#  printmimetree ();
#  printmimemainclasses ();
}



progmain;
# my @tarr;
# readutffile( \@tarr, $configfile);
  
# Misc stuff
###############################################################

sub show_help {
    print "Usage: $0 [OPTIONS]\n";
    print "Options:\n";
    print "\t--help             show this help and exit\n";
    print "\t--version          show the version and exit\n";
    print "\t--outpath=path     output file name, stdout if not specified\n";
#    print "\t--config=<file>    load config from file, default '$configfile'\n";
    print "\t--version|V        show version\n";
    print "\t--help|h|?         show this help\n";
    exit 0;
}

sub show_version {
    print "$version\n";
    exit 0;
}

sub wrong_usage {
    print STDERR "Try '$0 --help' for more information.\n";
    exit -1;
}

#	}
#       } elsif (lc $lstr eq lc "catindentst")
#       {
#         $catindentst = $rstr;
#       } elsif (lc $lstr eq lc "LocalLanguage")
#       {
#         $locallanguage = lc $rstr;
# #print "LocalLanguage: ", $_, "\n";
#       } elsif (lc $lstr eq lc "FallbackLanguage") 
#       {
#         $fallbacklanguage = lc $rstr;
# #print "FallbackLanguage: ", $_, "\n";
