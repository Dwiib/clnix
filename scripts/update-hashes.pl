#!/usr/bin/env perl
use strict;
use warnings;
use 5.34.0;

use Cwd qw(abs_path);
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename dirname);
use File::Slurp qw(read_file);
use JSON::MaybeXS qw(decode_json encode_json);
use LWP::Simple qw(get);

my $repo = abs_path( dirname( abs_path(__FILE__) ) . "/.." );

my $hashes_path = "$repo/quicklisp/hashes.json";
open my $hashes_file, "<", $hashes_path or die;
my %hashes = %{ decode_json( read_file($hashes_file) ) };
close $hashes_file or die;

my $unsaved = 0;

sub save {
    my $hashes_tmp = "$repo/quicklisp/.hashes.json.tmp";
    open $hashes_file, ">", $hashes_path or die;
    print $hashes_file encode_json( \%hashes );
    close $hashes_file or die;
}

foreach my $dist_path ( glob "$repo/quicklisp/dist-*.json" ) {
    next if basename($dist_path) eq "dist-latest.json";

    open my $dist_file, "<", $dist_path or die;
    my %projects = %{ decode_json( read_file($dist_file) ) };
    foreach my $project_name ( keys %projects ) {
        my %project = %{ $projects{$project_name} };
        my $url     = $project{"url"};
        my $md5     = $project{"md5"};
        next if exists $hashes{$md5};

        my $data = get($url);
        die "md5 mismatch for $project_name" unless md5_hex($data) eq $md5;
        say $url;
        $hashes{$md5} = sha256_hex($data);

        $unsaved++;
        if ( $unsaved > 10 ) {
            save;
        }
    }
}
