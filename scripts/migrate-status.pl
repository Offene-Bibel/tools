#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use v5.24;
binmode STDOUT, ":utf8";
binmode STDIN, ":utf8";

use Data::Printer;
use MediaWiki::Bot qw( :constants );
use YAML qw( LoadFile );;

my %config = LoadFile( 'config.yml' )->%*;

my @books = LoadFile( 'bibleBooks.yml' )->@*;

my $bot = MediaWiki::Bot->new({
    protocol   => 'http',
    host       => 'offene-bibel.de',
    path       => 'wiki',
    login_data => {
        username => $config{ bot_name },
        password => $config{ bot_password },
    },
    operator   => 'patrick.zimmermann',
    debug      => 3,
}) or die "Failed to create the bot.";


my %tags = ();
my $repls;

for my $book ( @books ) {
    for (my $chapter = 1; $chapter <= $book->{chapterCount}; $chapter++ ) {
        my $bookname = $book->{name};
        my $chaptername = $bookname . '_' . $chapter;

        my $text = $bot->get_text( $chaptername );

        # Replace old tags with their new counterparts.
        if ( $text ) {
            my $changed = 0;

            my $substs;
            $substs = $text =~ s/\{\{Lesefassung zu prüfen([^}]*)\}\}/{{Ungeprüfte Lesefassung$1}}/;
            $repls .= "\nReplacing \"$&\" with \"{{Ungeprüfte Lesefassung$1}}\" in $chaptername, $substs times." if $substs;
            $changed = 1 if $substs;

            $substs = $text =~ s/\{\{Studienfassung erfüllt die meisten Kriterien([^}]*)\}\}/{{Zuverlässige Studienfassung$1}}/;
            $repls .= "\nReplacing \"$&\" with \"{{Zuverlässige Studienfassung$1}}\" in $chaptername, $substs times." if $substs;
            $changed = 1 if $substs;

            $substs = $text =~ s/\{\{Studienfassung liegt in Rohübersetzung vor\}\}/{{Ungeprüfte Studienfassung}}/;
            $repls .= "\nReplacing \"$&\" with \"{{Ungeprüfte Studienfassung}}\" in $chaptername, $substs times." if $substs;
            $changed = 1 if $substs;

            if ( $changed ) {
                my $error = $bot->edit({
                    page    => $chaptername,
                    text    => $text,
                    summary => 'Alte Status durch die neuen Pendants ersetzen.',
                    bot     => 1,
                    assert  => 'bot',
                });

                if ( ! defined $error ) {
                    say "error: $chaptername, $bot->{ error }->{ code }, $bot->{ error }->{ details }";
                }
                else {
                    say "success: $chaptername";
                }
            }
        }

=pod
        # Count occurences of the different tag types.
        if ( $text ) {
            while ( $text =~ /\{\{[^\}]+\}\}/g ) {
                if( not $& =~ /^\{\{[LS]\|/ ) {
                    $tags{$&}++;
                }
            }
        }
=cut
    }
}

#p( %tags );
say $repls;

$bot->logout();

