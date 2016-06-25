#! /usr/bin/perl -w
use strict;

use Encode;
use utf8;
use POSIX;

use Getopt::Long;
use Date::Calc;
use File::Find;
use File::Basename;

my $opt_help=0;
my $opt_path="../database";

GetOptions( "help"         => \$opt_help,
            "path=s"       => \$opt_path
           );

if( $opt_help )
{
    print "holder_sus [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -p, --path                    database path [$opt_path]\n";
    exit(0);
}

(-e $opt_path && -e "$opt_path/holder") or die "input path error\n";

my @stock_array;

sub find_name
{
    my $file = fileparse( $File::Find::name );
    
    if( $file =~ m/^([0-9]+)\.csv/i )
    {
        my $stock = $1;
        
        push @stock_array, $stock;
    }
}

sub do_work;
sub main;

find( \&find_name, "$opt_path" ); 

my $loc_date = strftime "%F", localtime $^T;
my $loc_day  = strftime "%a", localtime $^T;
my $loc_year = strftime "%Y", localtime $^T;

!($loc_day =~ /Sat/ || $loc_day =~ /Sun/) or die "loc day error\n";

main();

sub main
{
    my %holders;
    
    foreach my $stock (@stock_array)
    {
        if( is_suspension( $stock ) )
        {
            do_work( \%holders, $stock );
        }
    }
    
    foreach my $holder (keys %holders)
    {
         print "$holder";
         print "$holders{$holder}\n";
    }
}

sub do_work
{
    my ($p_holders, $stock) = @_;
    my $filename_txt = "$opt_path/holder/$stock.txt";
    
    open FH, "$filename_txt" or die "open $filename_txt failed: $!\n";
    
    while(<FH>)
    {
        Encode::_utf8_on($_);
        
        if( /(.+),(.+),.+,.+/ )
        {
            my $date   = $1;
            my $holder = $2;
            
            if( $date =~ /$loc_year/ )
            {
                if( $holder =~ /^\w{2,3}$/ )
                {
                    $p_holders->{$holder} .= " $stock";
                }
            }
        }
    }
    
    close FH;
}

sub is_suspension
{
    my ($stock) = @_;
    my $filename_csv = "$opt_path/$stock.csv";
    
    open FH, "$filename_csv" or die "open $filename_csv failed: $!\n";
    
    while(<FH>)
    {
        if( /$loc_date/ )
        {
            return 0;
        }
    }
    
    close FH;
    
    return 1;
}
