#! /usr/bin/perl -w

use POSIX;
use Date::Calc;

use Getopt::Long;
use File::Find;
use File::Basename;

use alhena_database;

my $opt_help=0;
my $opt_stock;
my $opt_start;
my $opt_end;
my $opt_path="../database";

GetOptions( "help"         => \$opt_help,
            'name=s@{1,}'  => \$opt_stock,
            "start=s"      => \$opt_start,
            "end=s"        => \$opt_end,
            "database=s"   => \$opt_path
           );

if( $opt_help )
{
    print "range [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -n, --name                    specifiy the subject\n";
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

sub main;

if( !defined( $opt_stock ) )
{
    find( \&find_name, "$opt_path" ); 
}
else 
{
    foreach my $input (@$opt_stock)
    {
        if( -e $input )  # as filename
        {
            my $input_name = basename $input;
            
            # replace opt_path with input
            my $opt_path = dirname $input;
            
            $input_name =~ s/\.csv//;
            
            push @stock_array, $input_name;
        }
        elsif( -e "$opt_path/$input.csv" )
        {
            push @stock_array, $input;
        }
        else 
        {
            warn "input stock name error\n";
        }
    }
}

main();

sub main
{
    foreach my $stock (@stock_array)
    {
        my $delta = do_work( $stock );
        
        if( defined( $delta ) )
        {
            printf "%s,%.2f\n", $stock, $delta;
        }
    }
}

sub do_work
{
    my ($stock) = @_;
    my (@xdr_info, @database);
    my @result;
    
    read_old( $stock, $opt_path, \@xdr_info, \@database );
    
    foreach my $p_daily (@database)
    {
        if( delta_days_wrapper( $opt_start, $p_daily->{'date'} ) > 0 &&
            delta_days_wrapper( $p_daily->{'date'}, $opt_end ) > 0 )
        {
            push @result, $p_daily;
        }
    }
    
    return undef  if( @result == 0 );
    
    return delta_total( \@result );
}

sub delta_total
{
    my ($p_database) = @_;
    my $p_first = $p_database->[0];
    my $start   = $p_first->{'close'};
    my $p_end   = $p_database->[@$p_database - 1];
    my $end     = $p_end->{'close'};
    
    return ($end - $start) / $start;
}
