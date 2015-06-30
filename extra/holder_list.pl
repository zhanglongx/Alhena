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
my $opt_list="holder_list.txt";
my $opt_path="../database";

GetOptions( "help"         => \$opt_help,
            "list=s"       => \$opt_list,
            "path=s"       => \$opt_path
           );

if( $opt_help )
{
    print "holder_list [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -l, --list                    holder list ($opt_list)\n";
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
sub read_list;
sub read_holder;
sub main;

find( \&find_name, "$opt_path" ); 

main();

sub main
{
    my @list = read_list;
    
    foreach my $stock (@stock_array)
    {
        do_work $stock, \@list;
    }
}

sub do_work
{
    my ($stock, $p_list) = @_;
    my %holders;
    
    read_holder $stock, \%holders;
    
    print "$stock\n"   if( is_new( \%holders, $p_list ) );
}

sub read_list
{
    my @list;
    
    open FH, "$opt_list" or die "can't open $opt_list: $!\n";
    
    while(<FH>)
    {
        push @list, $_;
    }
    
    close FH;
    
    return @list;
}

sub read_holder
{
    my ($stock, $p_holders) = @_;
    my $filename = "$opt_path/holder/$stock.txt";
    
    open FH, "$filename" or die "can't open $filename: $!\n";
    
    while(<FH>)
    {
        my %entry;
        my $date;
        
        if( /(.*),(.*),(.*),(.*)/ )
        {
            $date = $1;
            $entry{'name'}    = $2;
            $entry{'vol'}     = $3;
            $entry{'percent'} = $4;
                        
            $date =~ s/-//g;  # convert to numeric
        }
        else
        {
            next;
        }
        
        push @{$p_holders->{$date}}, \%entry;
    }
    
    close FH;
}

sub is_new
{
    my ($p_holders, $p_list) = @_;
    my @names;
    
    # newest -> oldest
    my @dates = reverse sort keys %$p_holders;
    my $b_found = 0;
    
    return 0  if (@dates == 0);
    foreach my $list (@$p_list)
    {
        foreach my $holder (@{$p_holders->{$dates[0]}})
        {
            if( index( $holder->{'name'}, $list ) >= 0 )
            {
                $b_found = 1;
            }
        }
    }
    
    return 0  if( !$b_found );
    
    return 1  if( @dates == 1 );
    
    $b_found = 0;    
    foreach my $list (@$p_list)
    {
        foreach my $holder (@{$p_holders->{$dates[1]}})
        {
            if( index( $holder->{'name'}, $list ) >= 0 )
            {
                $b_found = 1;
            }
        }
    }
    
    return $b_found == 0 ? 1 : 0;
}
