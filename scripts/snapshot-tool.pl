#!/usr/bin/env perl
use v5.12;
use strict;

use FindBin;
use Getopt::Long;
use POSIX qw( strftime );
use File::Slurper qw( read_text write_text );

my @fileList = qw(
    mediawiki/LocalSettings.php
    mediawiki/skins/OffeneBibel/OffeneBibel.php
    mediawiki/extensions/di/iwDrupalConfig.php
    drupal/sites/default/settings.php
    drupal/sites/all/modules/mwi/mwi.config
);
my $webFolder = "/kunden/248589_32760/webseiten/offene-bibel.de";
my $snapshotFolder = "snapshot-" . strftime("%Y-%m-%d", localtime);
my $outputFile = $snapshotFolder . ".tgz";
my $dbUser = "db248589_10";
my $dbName = "db248589_10";
my $dbHost = "mysql5.offene-bibel.de";
my $dbPort = "3306";
my $domain = "offene-bibel.de";
my $drupal_salt;
my $mw_secret;
my $mode = $ARGV[0];

if ( not $mode ~~ [ 'fill', 'templatify', 'package' ]) {
    die "Wrong action given: \"$mode\" must be one of: fill, templatify, package.";
}

GetOptions ("source:s" => \$webFolder,
            "file:s"   => \$outputFile,
            "user:s"   => \$dbUser,
            "name:s"   => \$dbName,
            "host:s"   => \$dbHost,
            "port:i"   => \$dbPort,
            "folder:s" => \$snapshotFolder,
            "domain:s" => \$domain,
            "drupal_salt:s"   => \$drupal_salt,
            "mw_secret:s"   => \$mw_secret,
            )
            or die("Error in command line arguments\n");

print "Enter the DB password: ";
my $dbPassword = <STDIN>; chomp $dbPassword;

if ( $mode eq 'fill' ) {
    print 'Filling in database credentials... ';
        for (@fileList) {
            my $file = "$snapshotFolder/$_";
            my $template_file = $file . "_TEMPLATE";
            my $content = read_text( $template_file );
            $content =~ s/<&db_password&>/$dbPassword/g;
            $content =~ s/<&db_db&>/$dbName/g;
            $content =~ s/<&db_user&>/$dbUser/g;
            $content =~ s/<&db_host&>/$dbHost/g;
            $content =~ s/<&db_port&>/$dbPort/g;
            $content =~ s/<&domain&>/$domain/g;
            $content =~ s/<&drupal_hash_salt&>/$drupal_salt/g;
            $content =~ s/<&mw_secret&>/$mw_secret/g;
            chmod 0660, $file;
            write_text( $file, $content );
        }
    say 'done';
}
elsif ( $mode eq 'templatify' ) {
    for (@fileList) {
        my $file = "$snapshotFolder/$_";
        my $template_file = $file . "_TEMPLATE";
        my $content = read_text( $file );
        $content =~ s/$dbPassword/<&db_password&>/g;
        $content =~ s/$dbName/<&db_db&>/g;
        $content =~ s/$dbUser/<&db_user&>/g;
        $content =~ s/$dbHost/<&db_host&>/g;
        $content =~ s/$dbPort/<&db_port&>/g;
        $content =~ s/(?<!\@)$domain/<&domain&>/g;
        $content =~ s/$drupal_salt/<&drupal_hash_salt&>/g;
        $content =~ s/$mw_secret/<&mw_secret&>/g;
        chmod 0660, $template_file;
        write_text( $template_file, $content );
    }
}
elsif ( $mode eq 'package' ) {
    die "Output folder path already exists" if -e $snapshotFolder;
    die "Output file already exists" if -e $outputFile;

    mkdir $snapshotFolder;

    print 'Creating database dump... ';
        print `mysqldump -u$dbUser -p'$dbPassword' -h$dbHost $dbName -r$snapshotFolder/mysqldump.bin`;
    say 'done';

    print 'Copying files... ';
        print `cp -r $webFolder $snapshotFolder/offene-bibel.de`;
    say 'done';

    print 'Removing templated files... ';
    for (@fileList) {
        my $file = "$snapshotFolder/offene-bibel.de/$_";
        unlink $file;
    }
    say 'done';

    print 'Zipping... ';
        print `tar -czf $outputFile $snapshotFolder`;
    say 'done';

    print 'Removing temporary files... ';
        print `chmod -R u+w $snapshotFolder`;
        print `rm -rf $snapshotFolder`;
    say 'done';

    say 'Finished.';
}

