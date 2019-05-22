package Giblog;

use 5.008007;
use strict;
use warnings;

use Getopt::Long 'GetOptions';
use Giblog::API;
use Carp 'confess';
use Pod::Usage 'pod2usage';
use List::Util 'min';

our $VERSION = '0.90';

sub new {
  my $class = shift;
  
  my $self = {
    @_
  };
  
  return bless $self, $class;
}

sub _extract_usage {
  my $file = @_ ? "$_[0]" : (caller 1)[1];

  open my $handle, '>', \my $output;
  pod2usage -exitval => 'noexit', -input => $file, -output => $handle;
  $output =~ s/^.*\n|\n$//;
  $output =~ s/\n$//;

  return _unindent($output);
}

sub _unindent {
  my $str = shift;
  my $min = min map { m/^([ \t]*)/; length $1 || () } split "\n", $str;
  $str =~ s/^[ \t]{0,$min}//gm if $min;
  return $str;
}

sub run_command {
  my ($class, @argv) = @_;
  
  # Command line option
  local @ARGV = @argv;
  my $getopt_option_save = Getopt::Long::Configure(qw(default no_auto_abbrev no_ignore_case));
  GetOptions(
    "h|help" => \my $help,
    "H|home=s" => \my $home_dir,
  );
  Getopt::Long::Configure($getopt_option_save);
  
  # Command name
  my $command_name = shift @ARGV;
  
  # Show help
  die _extract_usage if $help || !$command_name;
  
  # Giblog
  my $giblog = Giblog->new(home_dir => $home_dir);
  
  # API
  my $api = Giblog::API->new(giblog => $giblog);
  
  # Add "lib" in home directory to include path 
  local @INC = @INC;
  if (defined $home_dir) {
    unshift @INC, "$home_dir/lib";
  }
  else {
    unshift @INC, "lib";
  }
  
  # Command is implemented in command
  my $command_class = "Giblog::Command::$command_name";
  eval "use $command_class;";
  if ($@) {
    confess "Can't load command $command_class:\n$!\n$@";
  }
  my $command = $command_class->new(api => $api);
  
  @argv = @ARGV;
  $command->run(@argv);
}

sub home_dir { shift->{'home_dir'} }
sub config { shift->{config} }

=head1 NAME

Giblog - Website and Blog builder

=head1 DESCRIPTION

Giblog is B<Website and Blog builder> written by Perl.

You can create B<your website and blog> easily.

All created files is B<static HTML>, so you can manage them using B<git>.

You can B<customize your website by Perl>.

Giblog is in beta test before 1.0 release. Note that features is changed without warnings.

=head1 SYNOPSYS
  
  # New empty web site
  giblog new mysite

  # New web site
  giblog new_website mysite

  # New blog
  giblog new_blog mysite
  
  # Change directory
  cd mysite
  
  # Add new entry
  giblog add

  # Build web site
  giblog build
  
  # Serve web site(need Mojolicious)
  morbo serve.pl

  # Add new entry with home directory
  giblog add --home /home/kimoto/mysite
  
  # Build web site with home directory
  giblog build --home /home/kimoto/mysite

=head1 FEATURES

Giblog have the following features.

=over 4

=item * Build Website and Blog.

=item * Linux, Mac OS, Windows Support. (In Windows, recommend installation of msys2)

=item * Responsive web site support. Default CSS is setup for PC and Smart phone.

=item * Header, Hooter and Side bar support

=item * You can customize Top and Bottom section of content.

=item * Automatical Line break. p tag is automatically added.

=item * Escape E<lt>, E<gt> automatically in pre tag

=item * Title tag is automatically added from first h1-h6 tag.

=item * Description meta tag is automatically added from first p tag.

=item * You can customize your web site by Perl programming laugnage.

=item * You can serve your web site in local environment. Contents changes is detected and build automatically(need L<Mojolicious>).

=item * Build 645 pages by 0.78 seconds in starndard linux environment.

=item * All build files is Static. you can manage files by Git.

=back

=head1 TUTORIAL

=head2 Create web site

B<1. Empty website>

"new" command create empty website. "mysite" is a name of your web site.

  giblog new mysite

If you want to create empty site, choice this command.

Templates and CSS is empty and provide minimal build script.

B<2. Website>

"new_website" command create simple website.  "mysite" is a name of your web site.

  giblog new_website mysite

If you want to create simple website, choice this command.

Top page "templates/index.html" is created. CSS supports responsive design and provide basic build script.

B<3. Blog>

"new_blog" command create empty website.  "mysite" is a name of your web site.

  giblog new_blog mysite

If you want to create blog, choice this prototype.

Top page "templates/index.html" is created, which show 7 days entries.

List page "templates/list.html" is created, which show all entries links.

CSS supports responsive design and provide basic build script.

=head2 Add blog entry page

You need to change directory to "mysite" before run "add" command if you are in other directory.

  cd mysite

"add" command add entry page.
  
  giblog add

Created file name is, for example,

  templates/blog/20080108132865.html

This file name contains current date and time.

Then open this file, write h2 head and content.

  <h2>How to use Giblog</h2>

  How to use Giblog. This is ...

Header and footer is automatically added.

=head2 Add content page

If you want to create content page, put file, for example "access.html", or "profile.html" into "templates" directory.

  templates/access.html
  templates/profile.html

Then open these file, write h2 head and content.

  <h2>How to use Giblog</h2>

  How to use Giblog. This is ...

Header and footer is automatically added.

=head2 Add static page

If you want to add static files like css, images, JavaScript, You put these file into "templates/static" directory.

Files in "templates/static" directory is only copied to public files by build script.

  templates/static/js/jquery.js
  templates/static/images/logo.png
  templates/static/css/more.css

=head2 Build web site

You need to change directory to "mysite" before run "build" command if you are in other directory.

  cd mysite

"build" command build web site.

  giblog build

What is build process?

Build script is writen in "lib/Giblog/Command/build.pm".

"build" command only execute "run" method in "Giblog::Command::build.pm" .

  # "lib/Giblog/Command/build.pm" in web site created by "new_blog" command
  package Giblog::Command::build;

  use base 'Giblog::Command';

  use strict;
  use warnings;

  use File::Basename 'basename';

  sub run {
    my ($self, @args) = @_;
    
    # API
    my $api = $self->api;
    
    # Read config
    my $config = $api->read_config;
    
    # Copy static files to public
    $api->copy_static_files_to_public;

    # Get files in templates directory
    my $files = $api->get_templates_files;
    
    for my $file (@$files) {
      # Data
      my $data = {file => $file};
      
      # Get content from file in templates directory
      $api->get_content($data);

      # Parse Giblog syntax
      $api->parse_giblog_syntax($data);

      # Parse title
      $api->parse_title_from_first_h_tag($data);

      # Edit title
      my $site_title = $config->{site_title};
      if ($data->{file} eq 'index.html') {
        $data->{title} = $site_title;
      }
      else {
        $data->{title} = "$data->{title} - $site_title";
      }

      # Add page link
      $api->add_page_link_to_first_h_tag($data, {root => 'index.html'});

      # Parse description
      $api->parse_description_from_first_p_tag($data);

      # Read common templates
      $api->read_common_templates($data);
      
      # Add meta title
      $api->add_meta_title($data);

      # Add meta description
      $api->add_meta_description($data);

      # Build entry html
      $api->build_entry($data);
      
      # Build whole html
      $api->build_html($data);
      
      # Write to public file
      $api->write_to_public_file($data);
    }
    
    # Create index page
    $self->create_index;
    
    # Create list page
    $self->create_list;
  }

You can customize build script if you need.

If you need to know Giblog API, see L<Giblog::API>.

=head2 Serve web site

If you have L<Mojolicious>, you can serve web site in local environment.

   morbo serve.pl

You see the following message.

   Server available at http://127.0.0.1:3000
   Server start

If files in "templates" directory is changed, Web site is automatically rebuild.

=head2 Customize header or footer, etc

You can customize header, footer, side bar, top of content, bottom of content.
  
  ------------------------
  Header
  ------------------------
  Top of content   |
  -----------------|
                   |Side
  Content          |bar
                   |
  -----------------|
  Bottom of content|
  ------------------------
  Footer
  ------------------------

If you want to edit these section, you edit these files.

  templates/common/bottom.html
  templates/common/footer.html
  templates/common/header.html
  templates/common/side.html
  templates/common/top.html

=head2 Customize HTML header

You can customize HTML header.

  <html>
    <head>
      <!-- HTML header -->
    </head>
    <body>
    
    </body>
  </html>

If you want to edit HTML header, you edit the following file.

  templates/common/meta.html

=head1 METHODS

These methods is internally methods.
Normally, you don't need to know these methods.
See L<Giblog::API> to manipulate HTML contents.

=head2 new

  my $api = Giblog->new(%params);

Create L<Giblog> object.

B<Parameters:>

=over 4

=item * home_dir - home directory

=item * config - config

=back

=head2 run_command

  $giblog->run_command(@argv);

Run command system.

=head2 config

  my $config = $giblog->config;

Get Giblog config.

=head2 home_dir

  my $home_dir = $giblog->home_dir;

Get home directory.

=head1 AUTHOR

Yuki Kimoto, C<< <kimoto.yuki at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018-2019 Yuki Kimoto.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
