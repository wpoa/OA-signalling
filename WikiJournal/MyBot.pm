package MyBot;

use strict;
use warnings;

use Carp;
use MediaWiki::API;

#
# Settings
#

my $_allnamespaces = "-1|-2|0|1|10|100|101|108|109|11|12|13|14|15|2|3|4|5|6|7|8|9|";

#
# Internal Subroutines
#

sub _loaduser {

  # This subroutine loads the user info for the bot.  It is passed the name of
  # the config file and returns the username and password.

  my $file = shift;

  open FILE, $file
    or croak "\nMyBot: Could not open user info file ($file)!\n  --> $!";

  my $username;
  my $password;

  while (<FILE>) {
    chomp;
    $username = (split /\s+=\s+/)[1] if (/^USERNAME/);
    $password = (split /\s+=\s+/)[1] if (/^PASSWORD/);
  }

  close $file;

  return $username, $password;
}

sub _api {

  # This subroutine executes an API call.  It is passed the calling function
  # and the parameters of the call and returns the results.

  my $self     = shift;
  my $function = shift;
  my $config   = shift;

  my $results;          # results of API call
  my $attempts = 0;     # number of times API called
  my $error    = 1;     # whether error returned

  while (($attempts lt $self->{settings}->{retries}) and ($error)) {

    $attempts++;
    $error = 0;

    $results = $self->{bot}->api( $config )
      or $error = 1;

    sleep $self->{settings}->{delay} if ($error);

  }

  if ($error) {
    croak "\n$function: " . $self->{bot}->{error}->{code} . ': ' . $self->{bot}->{error}->{details};
  }

  return $results;

}

sub _list {

  # This subroutine executes a list call.  It is passed the calling function
  # and the parameters of the call and returns the results.

  my $self     = shift;
  my $function = shift;
  my $config   = shift;

  my $results;          # results of API call
  my $attempts = 0;     # number of times API called
  my $error    = 1;     # whether error returned

  while (($attempts lt $self->{settings}->{retries}) and ($error)) {

    $attempts++;
    $error = 0;

    $results = $self->{bot}->list( $config )
      or $error = 1;

    sleep $self->{settings}->{delay} if ($error);

  }

  if ($error) {
    croak "\n$function: " . $self->{bot}->{error}->{code} . ': ' . $self->{bot}->{error}->{details};
  }

  return $results;

}

#
# External Subroutines
#

sub new {

  # This subroutine creates a new MyBot object.  It needs to be passed the
  # location of the user config file.  It optionally can be passed a lang
  # and a flag indicating don't login.

  my $class    = shift;
  my $userinfo = shift;
  my $lang     = shift;
  my $nologin  = shift;

  my $self = bless {}, $class;

  unless ($userinfo) {
    croak "\nMyBot->new: User configuration file not specified!";
  }

  $lang = 'en' unless ($lang);

  my $bot = MediaWiki::API->new( { 
      api_url => "http://$lang.wikipedia.org/w/api.php",
      max_lag => 5,
      max_lag_retries => -1,
      no_proxy => 1,
    }  );
  
  unless ($nologin) {
    my ($username, $password) = _loaduser($userinfo);

    $bot->login( {lgname => $username, lgpassword => $password } )
      or croak "\nMyBot->new: " . $bot->{error}->{code} . ': ' . $bot->{error}->{details};
  }

  $self->{bot} = $bot;

  $self->{settings}->{retries} = 10;
  $self->{settings}->{delay}   = 5;

  return $self;
}

sub getNamespaces {

  # This subroutine gets the namespaces & their values.  It returns a hash
  # containing the namespace number and name.

  my $self = shift;

  my $results = _api($self, "MyBot->getNamespaces", {
      action => 'query',
      meta   => 'siteinfo',
      siprop => 'namespaces',
    } );

  my $namespaces;

  for my $number ( keys %{ $results->{query}->{namespaces} } ) {

    my $canonical = $results->{query}->{namespaces}->{$number}->{canonical};
    $canonical = "Main" if ($number eq 0);
    
    $namespaces->{$canonical} = $number;
  
  }
  
  return $namespaces;
}

sub getCategoryMembers {

  # This subroutine gets the members of a category.  It is passed the category to be 
  # processed and an optional namespace filter.
  
  my $self       = shift;
  my $category   = shift;
  my $namespaces = shift;

  unless ($category) {
    croak "\nMyBot->getCategoryMembers: Category not specified!";
  }

  unless ($namespaces) {
    $namespaces = '0';
  }

  if ($namespaces eq "ALL") {
    $namespaces = $_allnamespaces;
  }

  my $results = _list($self, "MyBot->getCategoryMembers", {
      action      => 'query',
      list        => 'categorymembers',
      cmtitle     => $category,
      cmnamespace => $namespaces,
      cmlimit     => 'max'
    } );

  my $members;

  for my $result ( @$results ) {
    $members->{ $result->{title} } = 1;
  }

  return $members;
}

sub getBacklinks {

  # This subroutine gets the backlinks to a page.  It is passed the page to
  # process and two optional arguements: a binary flag for including backlinks
  # via redirects and a namespace filter.
  
  my $self       = shift;
  my $page       = shift;
  my $redirects  = shift;
  my $namespaces = shift;

  unless ($page) {
    croak "\nMyBot->getBacklinks: Page not specified!";
  }

  if ( ($redirects) and ($redirects ne 1) ) {
    croak "\nMyBot->getBacklinks: redirect option must be 0 or 1!";
  }

  unless ($namespaces) {
    $namespaces = '0';
  }

  if ($namespaces eq "ALL") {
    $namespaces = $_allnamespaces;
  }

  my $results = _list($self, "MyBot->getBacklinks", {
      action      => 'query',
      list        => 'backlinks',
      bltitle     => $page,
      blnamespace => $namespaces,
      blredirect  => $redirects,
      bllimit     => 'max'
    } );

  my $backlinks;

  for my $result ( @$results ) {

    $backlinks->{ $result->{title} } = 1 if (not exists $result->{redirect});
    
    if (exists $result->{redirlinks}) {
      for my $redirlinks ( @{$result->{redirlinks}} ) {
        $backlinks->{ $redirlinks->{title} } = 1;
      }
    }

  }


  return $backlinks;
}

sub getText {

  # This subroutine gets the text and timestamp of a page.  It is passed the
  # page to get.

  my $self = shift;
  my $page = shift;

  unless ($page) {
    croak "\nMyBot->getText: Page not specified!";
  }

  my $result    = $self->{bot}->get_page( { title => $page } );
  my $text      = $result->{'*'};
  my $timestamp = $result->{'timestamp'};
 
  while ( (not exists $result->{'missing'}) and (not $text) ) {

    # repeat attempt

    $result    = $self->{bot}->get_page( { title => $page } );
    $text      = $result->{'*'};
    $timestamp = $result->{'timestamp'};
    
  }

  return $text, $timestamp;
}

sub saveText {

  # This subroutine saves the new text of a page.  It is passed the page name,
  # the new text, the edit summary, a flag for minor edit, the timestamp for
  # when the page was edited, and a flag for a bot edit.

  my $self      = shift;
  my $page      = shift;
  my $timestamp = shift;
  my $text      = shift;
  my $summary   = shift;
  my $minor     = shift;
  my $isBot     = shift;

  unless ($page) {
    croak "\nMyBot->saveText: Page not specified!";
  }

  #unless ($timestamp) {                                    # no TS for new pages
  #  croak "\nMyBot->saveText: Timestamp not specified!";
  #}

  unless ($text) {
    croak "\nMyBot->saveText: Text not specified!";
  }

  unless ($summary) {
    croak "\nMyBot->saveText: Edit summary not specified!";
  }
  
  unless ( ($minor eq "Minor") or ($minor eq "NotMinor") ) {
    croak "\nMyBot->saveText: Minor flag needs to be 'Minor' or 'NotMinor'!";
  }

  unless ( ($isBot eq "Bot") or ($isBot eq "NotBot") ) {
    croak "\nMyBot->saveText: Bot flag needs to be 'Bot' or 'NotBot'!";
  }

  # force cached edit token to be cleared as token eventually expires in long run
  # -- will MediWiki::API eventually fix this?
  
  delete $self->{bot}->{config}->{tokens}->{edit} if (exists $self->{bot}->{config}->{tokens}->{edit});

  # create edit parameters and save page
  
  my $parameters = {
    action        => 'edit',
    title         => $page,
    text          => $text,
    summary       => $summary,
    basetimestamp => $timestamp,
  };

  $parameters->{minor} = 1 if ($minor eq "Minor");
  $parameters->{bot}   = 1 if ($isBot eq "Bot");

  $self->{bot}->edit( $parameters ) 
    or sub {
      carp "\nMyBot->saveText: " . $self->{bot}->{error}->{code} . ': ' . $self->{bot}->{error}->{details} . "\n";
      $self->{bot}->edit( $parameters ) 
        or croak "Failed again!\n";
    }

}

sub getTimestamp {

  # This subroutine gets the timestamp (last edit time) of a page.  It is
  # passed the page to check.

  my $self = shift;
  my $page = shift;

  unless ($page) {
    croak "\nMyBot->getTimestamp: Page not specified!";
  }

  my ($text, $timestamp) = getText($self, $page);

  $timestamp =~ /^(\d\d\d\d-\d\d-\d\d)T(\d\d:\d\d:\d\d)Z$/;
  my $date = $1;
  my $time = $2;

  croak "\nMyBot: Unable to parse timestamp ($timestamp)!" unless ($date and $time);

  return $date, $time
}

sub getTransclusions {

  # This subroutine gets the transclusions of a page.  It is passed the page to
  # process and a namespace filter.
   
  my $self       = shift;
  my $page       = shift;
  my $namespaces = shift;

  unless ($page) {
    croak "\nMyBot->getTransclusions: Page not specified!";
  }
 
  unless ($namespaces) {
    $namespaces = '0';
  }

  if ($namespaces eq "ALL") {
    $namespaces = $_allnamespaces;
  }

  # also process redirects if this is a template

  my $retrieve;

  if ($page =~ /^Template:/) {
    $retrieve = $self->getRedirects($page, 10);
  }

  $retrieve->{$page} = 1;

  # retrieve transclusions

  my $embedded;

  for my $transcluded (sort keys %$retrieve) {

    my $results = _list($self, "MyBot->getTransclusions", {
        action      => 'query',
        list        => 'embeddedin',
        eititle     => $transcluded,
        einamespace => $namespaces,
        eilimit     => 'max'
      } );

    for my $result ( @$results ) {
      $embedded->{ $result->{title} } = 1;
    }

  }

  return $embedded;
}

sub purgePage {

  # This subroutine purges a page.  It is passed the page to purge.
   
  my $self       = shift;
  my $page       = shift;

  unless ($page) {
    croak "\nMyBot->getTransclusions: Page not specified!";
  }
 
  _api($self, "MyBot->purgePage", {
      action  => 'purge',
      titles  => $page,
    } );

  return;
}

sub getPageLinks {

  # This subroutine gets all links on a page.  It is passed the page to process
  # and a namespace filter.

  my $self       = shift;
  my $page       = shift;
  my $namespaces = shift;

  unless ($page) {
    croak "\nMyBot->getTransclusions: Page not specified!";
  }

  unless ($namespaces) {
    $namespaces = '0';
  }

  if ($namespaces eq "ALL") {
    $namespaces = $_allnamespaces;
  }

  my $results = _api($self, "MyBot->getPageLinks", {
      action  => 'query',
      prop    => 'links',
      titles  => $page,
      pllimit => 'max'
    } );

  my ($id, $data) = %{$results->{query}->{pages}};

  my $links;    # hard ref

  for my $link ( @{ $data->{links} } ) {
    $links->{ $link->{title} } = 1;
  }

  return $links;
}

sub getHistory {

  # This subroutine gets information on the last edit of a page.  It is passed
  # the page to get.

  my $self = shift;
  my $page = shift;

  unless ($page) {
    croak "\nMyBot->getHistory: Page not specified!";
  }

  my $result = $self->{bot}->get_page( { title => $page } );
  
  my $text      = $result->{'*'};
  my $user      = $result->{'user'};
  my $timestamp = $result->{'timestamp'};
 
  if ( (not exists $result->{'missing'}) and (not $text) ) {
    use Data::Dumper;
    croak "\nMyBot->getHistory: Unknown result for $page\n" . Dumper ($result);
  }

  return $user, $timestamp;
}

sub getRedirects {

  # This subroutine gets all redirects to a page.  It is passed the page to
  # process and a namespace filter.
  
  my $self       = shift;
  my $page       = shift;
  my $namespaces = shift;

  unless ($page) {
    croak "\nMyBot->getRedirects: Page not specified!";
  }

  unless ($namespaces) {
    $namespaces = '0';
  }

  if ($namespaces eq "ALL") {
    $namespaces = $_allnamespaces;
  }

  my $results = _list($self, "MyBot->getRedirects", {
      action        => 'query',
      list          => 'backlinks',
      bltitle       => $page,
      blnamespace   => $namespaces,
      blredirect    => 1,
      blfilterredir => 'redirects',
      bllimit       => 'max'
    } );

  my $redirects;

  for my $result ( @$results ) {

    $redirects->{ $result->{title} } = 1;
    
    if (exists $result->{redirlinks}) {
      for my $redirlinks ( @{$result->{redirlinks}} ) {
        $redirects->{ $redirlinks->{title} } = 1;
      }
    }

  }

  return $redirects;
}

sub getExternalLinks {

  # This subroutine gets external links.  It is passed the base url to process
  # and a namespace filter.
  
  my $self       = shift;
  my $baseurl    = shift;
  my $namespaces = shift;

  unless ($baseurl) {
    croak "\nMyBot->getExternalLinks: URL not specified!";
  }

  unless ($namespaces) {
    $namespaces = '0';
  }

  if ($namespaces eq "ALL") {
    $namespaces = $_allnamespaces;
  }

  my $results = _list($self, "MyBot->getExternalLinks", {
      action        => 'query',
      list          => 'exturlusage',
      euquery       => $baseurl,
      eunamespace   => $namespaces,
      eulimit       => 'max'
    } );

  my $external;

  for my $result ( @$results ) {
    $external->{ $result->{url} }->{ $result->{title} } = 1;
  }

  return $external;
}

sub getDefaultSort {

  # This subroutine gets the defaultsort for a page  It is passed the page to
  # process.
  
  die;
  ## This does not work if a sort key is manually set for a category.
  ## It may return the manual set.

  my $self = shift;
  my $page = shift;

  unless ($page) {
    croak "\nMyBot->getDefaultSort: Page not specified!";
  }

  my $results = _api($self, "MyBot->getDefaultSort", {
      action  => 'query',
      prop    => 'categories',
      titles  => $page,
      clprop  => 'sortkey',
      cllimit => 1,
      eulimit => 'max'
    } );

  my $category = ( keys %{ $results->{query}->{pages} } )[0];

  return @{$results->{query}->{pages}->{$category}->{categories}}[0]->{sortkey};
}

sub checkTitle {

  # This subroutine checks a page to see if it is a redirect, missing,
  # interwiki, or invalid.  

  my $self = shift;
  my $page = shift;

  unless ($page) {
    croak "\nMyBot->getTarget: Page not specified!";
  }

  my $results = _api($self, "MyBot->getTarget", {
      action    => 'query',
      redirects => 1,
      titles    => $page
    } );
 
  if ($results->{query}->{redirects}) {
    # redirect so return target
    return "REDIRECT: @{$results->{query}->{redirects}}[0]->{to}";
  }

  if ($results->{query}->{interwiki}) {
    # interwiki 
    return 'INTERWIKI';
  }

  my $key = ( keys %{ $results->{query}->{pages} } )[0];

  if (exists $results->{query}->{pages}->{$key}->{missing}) {
    # page does not exist
    return 'MISSING';
  }

  if (exists $results->{query}->{pages}->{$key}->{invalid}) {
    # page is invalid
    return 'INVALID';
  }

  return 'EXISTING';
}

sub getStatistics {

  # This subroutine gets statistics (currently, only article count is
  # returned).

  my $self = shift;

  my $results = _api($self, "MyBot->getStatistics", {
      action => 'query',
      meta   => 'siteinfo',
      siprop => 'statistics',
    } );

  return $results->{query}->{statistics}->{articles};
}
1;
