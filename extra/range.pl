#! /usr/bin/perl -w

use POSIX;
use Date::Calc;

use Getopt::Long;
use File::Find;
use File::Basename;

my $opt_help=0;
my $opt_start;
my $opt_end;
my $opt_path="../database";

my $CONST_100M = 100000000;

GetOptions( "help"         => \$opt_help,
            "start=s"      => \$opt_start,
            "end=s"        => \$opt_end,
            "database=s"   => \$opt_path
           );

if( $opt_help )
{
    print "range [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -s, --start                   start date\n";
    print "    -e, --end                     end date\n";
    print "    -d, --database                database path [$opt_path]\n";
    exit(0);
}

defined( $opt_start ) or die "input start date\n";

unless( $opt_start =~ /[0-9]{4,4}-[0-9]{1,2}-[0-9]{1,2}/ )
{
    # FIXME: make it more strict
    die "start date format error\n";
}

unless( defined( $opt_end ) )
{
    $opt_end = strftime "%F", localtime $^T;
}

( -e $opt_path ) or die "input path error\n";

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
sub delta_total;
sub parse_date;
sub delta_days_wrapper;
sub main;

find( \&find_name, "$opt_path" ); 

main();

sub main
{
    foreach my $stock (@stock_array)
    {
        my $delta = do_work( $stock );
        
        if( defined( $delta ) )
        {
            print "$stock,$delta\n";
        }
    }
}

sub do_work
{
    my ($stock) = @_;
    my @database;
    my $filename_txt = "$opt_path/$stock.csv";
    
    open FH, "$filename_txt" or die "open $filename_txt failed: $!\n";
    
    while(<FH>)
    {
        # xdr info
        next  if( /^#\s+(\d+-\d+-\d+),([.0-9]+),([.0-9]+),([.0-9]+)/ );
        
        # real data
        if( /(\d+-\d+-\d+),(.*),(.*),(.*),(.*),(.*),(.*)/ )
        {
            my %one_day;
            
            $one_day{'date'}   = $1;
            $one_day{'open'}   = $2;
            $one_day{'high'}   = $3;
            $one_day{'low'}    = $4;
            $one_day{'close'}  = $5;
            $one_day{'vol'}    = $6;
            $one_day{'equity'} = $7;

            if( delta_days_wrapper( $opt_start, $one_day{'date'} ) > 0 &&
                delta_days_wrapper( $one_day{'date'}, $opt_end ) > 0 )
            {
                push @database, \%one_day;
            }
        }
    }
    
    close FH;
    
    return undef  if( @database == 0 );
    
    return delta_total( \@database );
}

sub delta_total
{
    my ($p_database) = @_;
    my $p_first = $p_database->[0];
    my $start   = $p_first->{'close'};
    my $p       = $p_database->[@$p_database - 1];
    my $end     = $p->{'close'};
    
    $p = $p_database->[@$p_database/2];
    my $mid = $p->{'close'};
    
    return ($mid > $start && $end > $mid) ? $end / $start : undef;
}

sub parse_date
{
    my ($date) = @_;
    
    if ( $date =~ m/(\d+)-(\d+)-(\d+)/ )
    {
        return ($1, $2, $3);
    }
    else
    {
        return (2007, 1, 1);
    }
}

sub delta_days_wrapper
{
    my ($date1, $date2) = @_;
    my ($year1, $month1, $day1) = parse_date $date1;
    my ($year2, $month2, $day2) = parse_date $date2;
    
    return Date::Calc::Delta_Days( $year1, $month1, $day1, $year2, $month2, $day2 );
}
