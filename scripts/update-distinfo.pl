#!/usr/bin/env perl

use strict;
use warnings;
use 5.34.0;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use JSON::MaybeXS qw(encode_json);
use LWP::Simple qw(get);

my %distinfo = ();
foreach ( split /\n/, get("http://beta.quicklisp.org/dist/quicklisp.txt") ) {
    /(.*): (.*)/;
    $distinfo{$1} = $2;
}

my %projects = ();
my %systems  = ();
foreach ( split /\n/, get( $distinfo{"release-index-url"} ) ) {
    my @comment_parts = split /#/, $_;
    my $line          = $comment_parts[0];
    my @parts         = split /\s+/, $line;
    next if ( @parts == 0 );

    my $project = shift @parts;
    my $url     = shift @parts;
    shift @parts;    # size
    my $md5 = shift @parts;
    shift @parts;    # content-sha1
    my $prefix = shift @parts;

    my %project_systems = ();
    foreach (@parts) {
        my %file_info = ();
        $project_systems{$_} = \%file_info;
    }

    my %project_info = (
        "url"     => $url,
        "md5"     => $md5,
        "prefix"  => $prefix,
        "systems" => \%project_systems,
    );
    $projects{$project} = \%project_info;
}
foreach ( split /\n/, get( $distinfo{"system-index-url"} ) ) {
    my @comment_parts = split /#/, $_;
    my $line          = $comment_parts[0];
    my @parts         = split /\s+/, $line;
    next if ( @parts == 0 );

    my $project     = shift @parts;
    my $system_file = shift @parts;
    my $system_name = shift @parts;
    my @deps        = @parts;

    $projects{$project}{"systems"}{"$system_file.asd"}{$system_name} =
      \@deps;
    my %system_load_info = (
        "project" => $project,
        "asd"     => "$system_file.asd"
    );
    push @{ $systems{$system_name} }, \%system_load_info;
}

my $distinfo_version = $distinfo{"version"};
my $repo             = abs_path( dirname( abs_path(__FILE__) ) . "/.." );
my $out_path         = "$repo/quicklisp/dist-$distinfo_version.json";
my %dist_info        = (
    "projects" => \%projects,
    "systems"  => \%systems,
);

open my $out, ">", $out_path or die;
print $out encode_json( \%dist_info ) or die;
close $out                            or die;

unlink "$repo/quicklisp/dist-latest.json";
symlink "dist-$distinfo_version.json", "$repo/quicklisp/dist-latest.json"
  or die;
