#!/cygdrive/c/Perl/bin/perl

use warnings;
use strict;

use lib "PATH-TO-DIRECTORY-WITH-MyBot";      # my modules

use MyBot;

use Benchmark;
use Getopt::Std;
use HTML::Entities;
use MediaWiki::DumpFile::FastPages;
use Sort::Naturally;
use URI::Escape qw( uri_escape_utf8 );
use Win32::WebBrowser;

use utf8;

#
# Configuration & Globals
#

my $gWorkDir  = 'PATH-TO-A-WORKING-DIRECTORY';    # working directory
my $gUserInfo = 'PATH-TO-A-BOT-PASSWORD-FIRL';    # user & pass info file

my @gCitations = (            # citation templates to look for
  'Template:Citation',
  'Template:Cite journal',
  'Template:Vancite journal',
  'Template:Vcite journal',
);

my $gDisambig = 'Category:Disambiguation message boxes';             # disabig template category

my @gInitials = (             # initials for files & output pages
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
  'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Num', 'Non',
);

my $gPageMax = 250;           # number of entries per output page
my $gPopular = 1000;          # number of most popular entries to output

my %gTitleFHS    = ();        # filehandles for title files
my %gCitationFHS = ();        # filehandles for citation files

#
# Subroutines
#

sub closeFiles {

  # This subroutine closes all open title files.

  for my $letter (@gInitials) {
    if (exists $gTitleFHS{$letter}) {
      my $fh = $gTitleFHS{$letter};
      close $fh
        or die "ERROR: Could not close file ($gWorkDir/journal-titles-$letter)!\n  --> $!\n\n";
    }
    if (exists $gCitationFHS{$letter}) {
      my $fh = $gCitationFHS{$letter};
      close $fh
        or die "ERROR: Could not close file ($gWorkDir/journal-journal-$letter)!\n  --> $!\n\n";
    }
  }

  return;
}

sub buildDisambigPattern {

  # This subroutine builds an OR pattern for matching disambig templates.  It
  # is passed the bot and the disambig template category. It returns the
  # pattern.

  my $bot      = shift;
  my $category = shift;

  print "Building disambig pattern ...\n";

  my $templates = $bot->getCategoryMembers($category, 10);

  my $pattern = '';

  for my $template (sort keys %$templates) {

    $pattern .= $template . '|';

    my $redirects = $bot->getRedirects($template, 10);
    for my $redirect (sort keys %$redirects) {
      $pattern .= $redirect . '|';
    }

  }

  $pattern =~ s/Template://g;
  $pattern =~ s/ /\[ _\]\+/g;
  $pattern =~ s/\|$//;

  $pattern = qr/\{\{\s*(?:Template\s*:\s*)?(?:$pattern)\s*(?:\||\})/io;

  return $pattern;
}

sub buildCitationPattern {

  # This subroutine builds an OR pattern for matching citation templates.  It
  # is passed the bot and the citation templates and returns the pattern.

  my $bot       = shift;
  my $templates = shift;

  print "Building citation pattern ...\n";

  my $pattern = '';

  for my $template (@$templates) {
    
    $pattern .= $template . '|';

    my $redirects = $bot->getRedirects($template, 10);
    for my $redirect (sort keys %$redirects) {
      $pattern .= $redirect . '|';
    }

  }

  $pattern =~ s/Template://g;
  $pattern =~ s/ /\[ _\]\+/g;
  $pattern =~ s/\|$//;

  $pattern = qr/^\{\{\s*(?:Template\s*:\s*)?(?:$pattern)\s*\|/io;

  return $pattern;
}

sub processTitle {

  # This subroutine processes the title and saves the results.  It is passed
  # the title, text, and the disambig template pattern.  It returns a flag
  # indicating whether or not the title should be processed for citations (i.e.
  # is it redirect).
  
  my $title   = shift;
  my $text    = shift;
  my $pattern = shift;

  # determine file to save results

  (my $initial = $title) =~ s/^(?:The\s)?(.).*$/$1/i;  # extract first character of title
  $initial = 'Non' if ($initial !~ /\p{IsASCII}/);     # non-letters and non-numbers
  $initial = 'Num' if ($initial !~ /\p{IsAlpha}/);     # numbers
  $initial = uc $initial if ($initial =~ /^[a-z]/);    # make sure alpha are uppercase
  
  my $fh = $gTitleFHS{$initial};

  # set default processing flag 
  
  my $process = 1;

  # check if a redirect, if it is save target
  # else check if a disambig, if it is save as dab 
  # otherwise save as normal

  if ($text =~ /^\s*#redirect\s*\[\[([^\]#]+)[\]#\n]/i) {
    (my $target = $1) =~ tr/_/ /;
    print $fh "$title\tREDIRECT\t$target\n";
    $process = 0;
  }
  elsif ($text =~ /$pattern/) {
    print $fh "$title\tDISAMBIG\t--\n";
  }
  else {
    print $fh "$title\tNORMAL\t--\n";
  }

  return $process;
}

sub findTemplates {

  # This subroutine finds templates in a text string.  It is passed the text
  # and returns an array reference containing the templates.

  my $text = shift;

  # the following code is based on perlfaq6's "Can I use Perl regular
  # expressions to match balanced text?" example
  
  my $regex = qr/
      (               # start of bracket 1
       {{             # match an opening template
        (?:
         [^{}]++      # one or more non brackets, non backtracking
          |
         (?1)         # recurse to bracket 1
        )*
       }}             # match a closing template
      )               # end of bracket 1
     /x;
  
  my @queue   = ( $text );
  my @templates = ();
  
  while( @queue ) {
    my $string = shift @queue;
    my @matches = $string =~ m/$regex/go;
    @templates = ( @templates, @matches);
    unshift @queue, map { s/^{{//; s/}}$//; $_ } @matches;
  }
  
  return \@templates;
  
}

sub processJournalField {

  # This subroutine processes the journal field.  It is passed the field text
  # and the article from which it came.

  my $field = shift;
  my $title = shift;

  my $display = $field;
  
  # calculate display by stripping out links and unwanted formatting 

  $display =~ s/<html_ent glyph="\@amp;" ascii="&amp;"\/>/&/ig;  # replace <html_ent glyph="@amp;" ascii="&amp;"/>

  $display =~ s/_/ /g;                                    # ensure spaces (wiki syntax) 
  $display =~ s/&nbsp;/ /g;                               # ensure spaces (non-breaking)
  $display =~ s/<br\s*\/>/ /g;                            # ensure spaces (breaks)
  $display =~ s/\s{2,}/ /g;                               # ensure only single space

  $display =~ s/\[\[([^\|]+)\|\s*\]\]/$1/g;               # handle special case [[link| ]]

  $display =~ s/\[\[(?:[^\|]+\|\s*)([^\]]+)\s*\]\]/$1/g;           # remove link from [[link|text]]
  $display =~ s/\[\[(?:[^\{]+{{\s*!\s*}}\s*)([^\]]+)\s*\]\]/$1/g;  # remove link from [[link{{!}}text]]
  $display =~ s/\[\[\s*([^\]]+)\s*\]\]/$1/g;                       # remove link from [[text]]

  $display =~ s/\[\s*https?:[^\s\]]+\]//g;                # remove [http://link]
  $display =~ s/\[\s*https?:[^\s]+\s+([^\]]+)\]/$1/g;     # remove link from [http://link text]
  $display =~ s/{{\s*URL\s*\|[^\|]+\|\s*(.+?)\s*}}/$1/g;  # remove link from {{URL|link|text}}

  $display =~ s/\s*<!--[^\>]*-->//g;                      # remove <!--comments-->

  $display =~ s/<abbr\s.*?>(.*?)<\/abbr\s*>/$1/ig;        # remove <abbr ...>text</abbr>
  $display =~ s/<span\s.*?>(.*?)<\/span\s*>/$1/ig;        # remove <span ...>text</span>

  $display =~ s/{{\s*lang\s*\|[^\|]+\|([^\}]+)}}/$1/ig;   # remove {{lang|ln|text}}

  $display =~ s/{{\s*nihongo\s*\|([^\}\|]+)\|.*?}}/$1/ig;    # remove {{nihongo|text|...}}
  $display =~ s/{{\s*nihongo\s*\|\|([^\\|}]+)\|.*?}}/$1/ig;  # remove {{nihongo||text|...}}

  $display =~ s/{{\s*asiantitle\s*\|[^\|]*\|[^\|]*\|([^\}\|]+).*?}}/$1/ig;  # remove {{asiantitle|no|no|text|...}}
  $display =~ s/{{\s*asiantitle\s*\|[^\|]*\|([^\}\|]+).*?}}/$1/ig;          # remove {{asiantitle|no|text|...}}
  $display =~ s/{{\s*asiantitle\s*\|([^\}\|]+).*?}}/$1/ig;                  # remove {{asiantitle|text|...}}

  $display =~ s/{{\s*ill\s*\|[^\|]*\|([^\}\|]+).*?}}/$1/ig;                 # remove {{ill|no|text|...}}
  $display =~ s/{{\s*link-interwiki\s*\|\s*en\s*=\s*([^\}\|]+).*?}}/$1/ig;  # remove {{link-interwiki|en=text|...}}

  $display =~ s/\s*{{\s*unicode\s*\|([^\}]+)}}/$1/ig;     # remove {{unicode|text}}
  $display =~ s/\s*{{\s*polytonic\s*\|([^\}]+)}}/$1/ig;   # remove {{polytonic|text}}

  $display =~ s/\s*{{\s*lang-el\s*\|[^\}]+}}//ig;         # remove {{lang-el|remove}}
  $display =~ s/\s*{{\s*lang-en\s*\|[^\}]+}}//ig;         # remove {{lang-en|remove}}
  $display =~ s/\s*{{\s*lang-ru\s*\|[^\}]+}}//ig;         # remove {{lang-ru|remove}}
  $display =~ s/\s*{{\s*nihongo2\s*\|[^\}]+}}//ig;        # remove {{nihongo2|remove}}
  $display =~ s/\s*{{\s*hebrew\s*\|[^\}]+}}//ig;          # remove {{hebrew|remove}}
 
  $display =~ s/{{\s*okina\s*}}/&#x02BB;/ig;              # replace {{okina}}
  $display =~ s/{{\s*!\s*}}/|/ig;                         # replace {{!}}

  $display =~ s/{{\s*sup\s*\|([^\}]+)}}/$1/ig;            # remove {{sup|text}}

  $display =~ s/\s*{{\s*dn\s*(?:\|.*?)?}}//ig;                     # remove {{dn|date=...}}
  $display =~ s/\s*{{\s*disambiguation needed\s*(?:\|.*?)?}}//ig;  # remove {{disambiguation needed|date=...}}

  $display =~ s/\s*{{\s*clarify\s*(?:\|.*?)?}}//ig;                # remove {{clarify|date=...}}

  $display =~ s/\s*{{\s*dead link\s*(?:\|.*?)?}}//ig;              # remove {{Dead link|date=...}}

  $display =~ s/\s*{{\s*sic\s*(?:\|.*?)?}}//ig;                    # remove {{sic|remove}}

  $display =~ s/\s*{{\s*date\s*(?:\|.*?)?}}//ig;                   # remove {{date|remove}}

  $display =~ s/{{\s*ECCC\s*\|.*?\|\s*(\d+)\s*\|\s*(\d+)\s*}}/ECCC TR$1-$2/ig;  # remove {{ECCC|no|num|num}}

  $display =~ s/,?\s*{{\s*ODNBsub\s*}}//ig;               # remove {{ODNBsub}}           
  $display =~ s/\s*{{\s*arxiv\s*\|[^\}]*}}//ig;           # remove {{arxiv}}
  $display =~ s/\s*{{\s*paywall\s*}}//ig;                 # remove {{paywall}}
  $display =~ s/\s*{{\s*registration required\s*}}//ig;   # remove {{registration required}}
  
  $display =~ s/\s*{{\s*subscription required\s*(?:\|.*?)?}}//ig;  # remove {{subscription required|remove}}
  $display =~ s/\s*{{\s*subscription\s*(?:\|.*?)?}}//ig;           # remove {{subscription|remove}}

  $display =~ s/{{\s*Please check ISBN\s*\|([^\}]+)}}//ig;         # remove {{Please check ISBN|remove}}

  $display =~ s/{{\s*nowrap\s*\|([^\}]+)}}/$1/ig;         # remove {{nowrap|text}}

  $display =~ s/{{\s*spaced ndash\s*}}/ – /ig;            # replace {{spaced ndash}}

  $display =~ s/^''(.*)''\s'''(.*)'''$/$1 $2/g;           # handle special case ''text'' '''text'''

  $display =~ s/^'{2,5}(.*?)'{2,5}$/$1/g;                 # remove italics and bold
  $display =~ s/^[\"“](.*?)[\"”]$/$1/g;                   # remove quotes (regular & irregular)

  $display =~ s/<sup>([^\<]+)?<\/sup>/$1/g;               # remove <sub>text</sub>
  $display =~ s/<small>([^\<]+)?<\/small>/$1/g;           # remove <small>text</small>

  $display =~ s/<nowiki>([^\<]+)<\/nowiki>/$1/g;          # remove <nowiki>text</nowiki>

  $display =~ s/\s\[[^\]]*\]$//;                          # remove [note]$
  $display =~ s/^\[(.*)\]$/$1/;                           # remove [text]$

  $display = decode_entities($display);                   # decode HTML entities (&amp; etc)

  $display =~ s/\s*\(\)//g;                               # remove ()

  $display =~ s/\s+'+$//;                                 # remove '' at end
  $display =~ s/\s*,\s*$//;                               # remove , at end

  $display =~ s/^\s+//;                                   # remove space at start
  $display =~ s/\s+$//;                                   # remove space at end

  # skip if results in nothing (ex. comment only)

  return if ($display =~ /^\s*$/);
  return if ($display =~ /^\s*\.\s*$/);

  # make sure display starts with uppercase if alpha

  $display = ucfirst $display if ($display =~ /^[a-z]/);

  # open file in which to save results 

  (my $initial = $display) =~ s/^(?:The\s)?(.).*$/$1/i;  # extract first character of title
  $initial = uc $initial;                                # ensure uppercase
  $initial = 'Non' if ($initial !~ /\p{IsASCII}/);       # non-letters and non-numbers
  $initial = 'Num' if ($initial !~ /\p{IsAlpha}/);       # numbers
  $initial = uc $initial if ($initial =~ /^[a-z]/);      # make sure alpha are uppercase

  my $fh = $gCitationFHS{$initial};

  # save results 

  $field =~ s/\n/##/g;

  print $fh "$display\t$title\t$field\n";

  return;
}

sub mycmp {

  # This subroutine is a custom cmp routine to get the necessary sort order.

  my $oa = shift;
  my $ob = shift;

  (my $na = $oa) =~ s/^The //i;
  (my $nb = $ob)  =~ s/^The //i;

  # if they are the same (one with & one w/o "The"), compare originals so sorted consistently

  if ($na eq $nb) {             
    return ncmp($a, $b);
  }

  # if not the same, compare without

  return ncmp($na, $nb);
}

sub mostPopular {

  # This subroutine tracks the most popular.  It is passed a hash reference
  # (either to the existing or missing), the display title, the citation count,
  # and the output string

  my $ref       = shift;
  my $display   = shift;
  my $citations = shift;
  my $output    = shift;

  if ($citations < $ref->{threshold}) {
    die "ERROR: should not reach here (mostPopular)!\n";
  }

  $ref->{citations}->{$citations}->{$display} = $output;
  $ref->{count}++;

  # check if need to trim results
  # use 2 x $gPopular to avoid being less than $gPopular due to duplicates 

  if ($ref->{count} > (2 * $gPopular)) {

    # find smallest & reset threshold to it

    my $smallest = (sort { $a <=> $b } keys %{$ref->{citations}})[0];
    $ref->{threshold} = $smallest;

    # delete smallest 

    delete $ref->{citations}->{$smallest};

    # reset count to remaining

    $ref->{count} = 0;
    for my $citations (keys %{$ref->{citations}}) {
      $ref->{count} += scalar keys %{$ref->{citations}->{$citations}};
    }

  }

  return $ref;
}

sub parseDate {

  # This subroutine parses the dump date from the dumpfile name.  It is passed
  # the filename and returns the date.

  my $file = shift;

  if ($file =~ /enwiki-(\d+)-pages-articles/) {
    return $1;
  }

  die "ERROR: Could not parse dump date ($file)!\n\n";
}

#
# Main
#

# command line options

my %opts;
getopts('hps', \%opts);

if ($opts{h}) {
  print "usage: wiki-bot-journal [-hps] <file>\n";
  print "       where: -h = help\n";
  print "              -p = parse only\n";
  print "              -s = save to Wikipedia only\n";
  print "       -p and -s are mutually exclusive\n";
  exit;
}

my $pFlag = $opts{p} ? $opts{p} : 0;      # specify parse only
my $sFlag = $opts{s} ? $opts{s} : 0;      # specify save only

my $wikifile = $ARGV[0];                  # specify file to process

if ((not $wikifile) or (($pFlag) and ($sFlag))) {
  die "usage: wiki-bot-journal [-hps] <file>\n";
}

my $wikidate = parseDate($wikifile);

# handle UTF-8

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

# auto-flush output

$| = 1;

# working directory:

chdir $gWorkDir
  or die "\nError: Could not change to working die ($gWorkDir)\n  --> $!\n\n";

# gracefully quit on interrupt

$SIG{'INT'} = sub { 
  closeFiles;
  exit; 
};

# initialize bot

my $bot = MyBot->new($gUserInfo);

# skip parsing if save only specified

goto WIKIPEDIA if ($sFlag);

# delete existing files

my @files = glob "$gWorkDir/journal-*";
for my $file (@files) {
  unlink $file
    or die "ERROR: Could not delete file ($file)\n --> $!\n\n";
}

# open title files for read/write

for my $letter (sort @gInitials) {
  local *FH;
  open FH, '>:utf8', "$gWorkDir/journal-titles-$letter"
    or die "ERROR: Could not open file ($gWorkDir/journal-titles-$letter)!\n  --> $!\n\n";
  $gTitleFHS{$letter} = *FH;
}

# open citation files for read/write

for my $letter (sort @gInitials) {
  local *FH;
  open FH, '>:utf8', "$gWorkDir/journal-citations-$letter"
    or die "ERROR: Could not open file ($gWorkDir/journal-citations-$letter)!\n  --> $!\n\n";
  $gCitationFHS{$letter} = *FH;
}

# build regex patterns

my $pDisambig = buildDisambigPattern($bot, $gDisambig);
my $pCitation = buildCitationPattern($bot, \@gCitations);

# parse dump file

print "Parsing titles ...\n";

my $pages = MediaWiki::DumpFile::FastPages->new($wikifile);

my $p0 = Benchmark->new;
my $cTitles    = 0;
my $cCitations = 0;

while (my ($title, $text) = $pages->next) {

  # ignore non-article namespace (not sure why even in dump)

  next if ($title =~ /^Book:/);
  next if ($title =~ /^Category:/);
  next if ($title =~ /^File:/);
  next if ($title =~ /^Help:/);
  next if ($title =~ /^MediaWiki:/);
  next if ($title =~ /^Portal:/);
  next if ($title =~ /^Template:/);
  next if ($title =~ /^Wikipedia:/);

  $cTitles++;

  if (($cTitles % 10000) == 0) {          
    print "  count = $cTitles\r";
  }

  # process title & only proceed if not a redirect

  my $process = processTitle($title, $text, $pDisambig);
  next unless ($process);

  # skip unless contains a journal parameter

  next unless ($text =~ /\|\s*journal\s*=/);

  # check for and process templates
  
  my $templates = findTemplates($text);
 
  for my $template (@$templates) {
    if ($template =~ /$pCitation/) {
      if ($template =~ /\|\s*journal\s*=\s*((?:.*?(?:[{\[]+.*?[}\]]+)*)*)\s*(?:\||\}\})/i) {

        my $field = $1;

        next if ($field =~ /^\s*$/);      # skip blank parameters

        $cCitations++;

        processJournalField($field, $title);

      }
    }
  }
}

my $p1 = Benchmark->new;
my $pd = timediff($p1, $p0);
my $ps = timestr($pd);
$ps =~ s/^\s*(\d+)\swallclock secs.*$/$1/;
print "  $cTitles titles & $cCitations citations processed in $ps seconds\n";

# done writing files 

closeFiles;

# loop through each letter and generate output

print "Generating output ...\n";

my $o0 = Benchmark->new;
my $cOutput = 0;

my $pAll->{threshold}     = 0;            # hash ref to track most popular 
my $pMissing->{threshold} = 0;            # hash ref to track most popular missing 

for my $letter (@gInitials) {

  print "  processing $letter\r";

  # read in titles

  open TITLES, '<:utf8', "$gWorkDir/journal-titles-$letter"
    or die "ERROR: Could not open file ($gWorkDir/journal-titles-$letter)!\n  $!\n\n";

  my $titles;

  while (<TITLES>) {
    if (/^(.+?)\t(.+?)\t(.+?)$/) {
      my $title  = $1;
      my $type   = $2;
      my $target = $3;
      $titles->{$title}->{$type} = $target;
    }
    else {
      warn "should not reach here1!\n[$_]\n\n";
    }
  }

  close TITLES;

  # read in citations

  open CITATIONS, '<:utf8', "$gWorkDir/journal-citations-$letter"
    or die "ERROR: Could not open file ($gWorkDir/journal-citations-$letter)!\n  $!\n\n";

  my $journals;

  while (<CITATIONS>) {

    if (/^(.+)\t(.+)\t.+$/) {

      my $display = $1;
      my $article = $2;

      $journals->{$display}->{count}++;
      $journals->{$display}->{articles}->{$article} = 1;

    }
    else {
      warn "should not reach here2!\n[$_]\n\n";
    }

  }

  close CITATIONS;

  # merge (journal), (magazine}, & (newspaper) as appropriate

  for my $display (keys %$journals) {

    my $pJournal   = "$display (journal)";
    my $pMagazine  = "$display (magazine)";
    my $pNewspaper = "$display (newspaper)";

    my $merge;

    # check if merge needed in priority order

    if (exists $journals->{$pJournal}) {
      $merge = $pJournal;
    }
    elsif (exists $journals->{$pMagazine}) {
      $merge = $pMagazine;
    }
    elsif (exists $journals->{$pNewspaper}) {
      $merge = $pNewspaper;
    }
 
    # merge if needed

    if ($merge) {

      $journals->{$display}->{count} += $journals->{$merge}->{count};     # combine counts
      for my $article (keys %{$journals->{$merge}->{articles}}) {         # combine articles
        $journals->{$display}->{articles}->{$article} = 1;
      }
      delete $journals->{$merge};                                         # delete merged 

      $journals->{$display}->{merge} = $merge;                            # record merged

    }

  }

  # output results

  open OUTPUT, '>:utf8', "$gWorkDir/journal-output-$letter"
    or die "ERROR: Could not open file ($gWorkDir/journal-output-$letter)!\n  $!\n\n";
  
  for my $display (sort { mycmp($a, $b) } keys %$journals) {

    $cOutput++;

    # possible (journal), (magazine}, & (newspaper) variants

    my $pJournal   = "$display (journal)";
    my $pMagazine  = "$display (magazine)";
    my $pNewspaper = "$display (newspaper)";

    # generate journal & target fields

    my $journal;      # journal field
    my $target;       # target field

    my $exists = 1;   # flag to track existing or not
  
    if ($display =~ /^CA:/i) {                                      # special case
      $journal = "<nowiki>$display</nowiki>";
      $target  = "Invalid";
    }
    elsif ($display =~ /^DA:/i) {                                   # special case
      $journal = "<nowiki>$display</nowiki>";
      $target  = "Invalid";
    }
    elsif ($display =~ /[#<>\[\]\|{}_]/) {                          # invalid title characters
      $journal = "<nowiki>$display</nowiki>";
      $target  = "Invalid";
    }
    elsif (exists $titles->{$pJournal}->{NORMAL}) {                 # (journal) variant exists as normal page
      $journal = "'''[[$pJournal|$display]]'''";
      $target  = "[[$pJournal]]";
    }
    elsif (exists $titles->{$pMagazine}->{NORMAL}) {                # (magazine) variant exists as normal page
      $journal = "'''[[$pMagazine|$display]]'''";
      $target  = "[[$pMagazine]]";
    }
    elsif (exists $titles->{$pNewspaper}->{NORMAL}) {               # (newspaper) variant exists as normal page
      $journal = "'''[[$pNewspaper|$display]]'''";
      $target  = "[[$pNewspaper]]";
    }
    elsif (exists $titles->{$display}->{NORMAL}) {                  # normal page        
      $journal = "'''[[$display]]'''";
      $target  = "[[$display]]";
    }
    elsif (exists $titles->{$display}->{DISAMBIG}) {                # dab page
      $journal = "'''[[$display|<u>$display</u>]]'''";              
      $target  = "[[$display]]";
    }
    elsif (exists $titles->{$display}->{REDIRECT}) {                # redirect page
      my $redirect = $titles->{$display}->{REDIRECT};
      if (exists $titles->{$redirect}->{DISAMBIG}) {                # redirect to a dab
        $journal = "''[[$display|<u>$display</u>]]''";
      }
      else {                                                        # other redirect
        $journal  = "''[[$display]]''";
      }
      $target  = "[[$redirect]]";
    }
    else {                                                          # does not exist
      # need to handle invalid characters
      $journal = "[[$display]]";
      $target  = '&mdash;';
      $exists = 0;
    }

    # generate "Citations" column

    my $citations = $journals->{$display}->{count};

    # generate "Articles" column

    my $count = scalar keys %{$journals->{$display}->{articles}};

    my $articles;

    if ($count <= 5) {
      my $index = 0;
      for my $article (sort keys %{$journals->{$display}->{articles}}) {
        $index++;
        $articles .= ',&nbsp;' unless ($index == 1);
        $articles .= "[[$article|$index]]";
      }
    }
    else {
      $articles = $count;
    }  

    # generate "Search" column

    my $urlencode = uri_escape_utf8($display);

    # prevent display from breaking row template
    # NOTE: This could have a side affect on mostPopular (sorting?), but unlikely
    # as these should not make the mostPopular list.
    
    if ( ($display =~ /[\[\]\|]/) or 
         ($display =~ /<!--/) ) {
      $display = "<nowiki>$display</nowiki>";
    }

    # for {{JCW-row}} template, $display is the journal (unformatted) and $journal is the $display (formatted)

    my $output = "journal=$display|display=$journal|target=$target|citations=$citations|articles=$articles|search=$urlencode";

    print OUTPUT "$output\n";

    # track most popular

    if ($pAll->{threshold} < $citations) {
      $pAll = mostPopular($pAll, $display, $citations, $output);
    }
    if ((not $exists) and ($pMissing->{threshold} < $citations)) {
      $pMissing = mostPopular($pMissing, $display, $citations, $output);
    }

  }

  close OUTPUT;

}

my $o1 = Benchmark->new;
my $od = timediff($o1, $o0);
my $os = timestr($od);
$os =~ s/^\s*(\d+)\swallclock secs.*$/$1/;
print "  $cOutput journals output in $os seconds\n";

# generate most popular 

print "Generating most popular ...\n";

open OUTPUT, '>:utf8', "$gWorkDir/journal-output-Popular"
  or die "ERROR: Could not open file ($gWorkDir/journal-output-Popular)!\n  $!\n\n";

my $cAll = 1;
for my $citations (reverse sort { $a <=> $b } keys %{$pAll->{citations}}) {
  my $number = $cAll;
  for my $display (sort keys %{$pAll->{citations}->{$citations}}) {
    print OUTPUT "rank=$number|$pAll->{citations}->{$citations}->{$display}\n";
    $cAll++;
  }
  last if ($cAll >= $gPopular);
}

close OUTPUT;

# generate most popular missing

print "Generating most popular missing ...\n";

open OUTPUT, '>:utf8', "$gWorkDir/journal-output-Missing"
  or die "ERROR: Could not open file ($gWorkDir/journal-output-Missing)!\n  $!\n\n";

my $cMissing = 1;
for my $citations (reverse sort { $a <=> $b } keys %{$pMissing->{citations}}) {
  my $number = $cMissing;
  for my $display (sort keys %{$pMissing->{citations}->{$citations}}) {
    print OUTPUT "rank=$number|$pMissing->{citations}->{$citations}->{$display}\n";
    $cMissing++;
  }
  last if ($cMissing >= $gPopular);
}

close OUTPUT;

# quit if parse only specified

if ($pFlag) {
  exit;
}

# save results to Wikipedia
WIKIPEDIA:

print "Saving to Wikipedia ...\n";

for my $letter (@gInitials, 'Popular', 'Missing') {

  # read in results

  open INPUT, '<:utf8', "$gWorkDir/journal-output-$letter"
    or die "ERROR: Could not open file ($gWorkDir/journal-output-$letter)!\n  $!\n\n";

  my @results = <INPUT>;

  close INPUT;

  # generate pages

  my $pCurrent = 1;                  # current page number
  my $rPage    = 0;                  # current record number within page
  my $rTotal   = 0;                  # total records output so far
  my $rMaximum = scalar(@results);   # maximum records to output

  my $output;                        # page output

  for my $line (@results) {

    chomp $line;

    $rPage++;
    $rTotal++;

    if ($rPage == 1) {
      $output = "{{JournalsMain}}\n";
      $output .= "{{JournalsLetter|letter=$letter}}\n";
      $output .= "{{JCW-top";
      $output .= "|rank=Yes" if (($letter eq 'Popular') or ($letter eq 'Missing'));
      $output .= "}}\n";
    }

    $output .= "{{JCW-row|$line}}\n";
    
    # if we reach the maximum for the page or the last possible record, end page

    if (($rPage == $gPageMax) or ($rTotal == $rMaximum)) {

      $output .= "{{JCW-bottom|date=$wikidate}}\n{{JournalsPrevNext|previous=";
      $output .= $letter . ($pCurrent - 1) if ($pCurrent > 1);
      $output .= "|current=$letter$pCurrent|next=";
      $output .= $letter . ($pCurrent + 1) if ($rTotal < scalar(@results));
      $output .= '}}';

      print "  saving $letter$pCurrent ...           \r";

      my $page = "Wikipedia:WikiProject Academic Journals/Journals cited by Wikipedia/$letter$pCurrent";
      my ($text, $timestamp) = $bot->getText($page);
      $bot->saveText($page, $timestamp, $output, 'updating Wikipedia citation statistics', 'NotMinor', 'Bot');
      
      $pCurrent++;      
      $rPage = 0;

    }
    
  }

  close INPUT;

  # open last page for current letter
  # allows checking if a prior page needs to be deleted

  my $lastNumber = $pCurrent - 1;
  my $lastPage = "Wikipedia:WikiProject Academic Journals/Journals cited by Wikipedia/$letter$lastNumber";
  open_browser("http://en.wikipedia.org/wiki/$lastPage")
    or die "\nError: died on displaying page ($lastPage)\n --> $!\n\n";

}
