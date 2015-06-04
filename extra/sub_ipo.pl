#! /usr/bin/perl -w

use Getopt::Long;
use File::Find;
use File::Basename;

my $opt_help=0;
my $opt_total=120;
my $opt_equity=80;      # unit 100M
my $opt_percent=4.5;
my $opt_recent=20;
my $opt_path="../database";

my $CONST_100M = 100000000;

GetOptions( "help"         => \$opt_help,
            "total=i"      => \$opt_total,
            "equity=i"     => \$opt_equity,
            "percent=f"    => \$opt_percent,
            "database=s"   => \$opt_path
           );

if( $opt_help )
{
    print "sub_ipo [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -t, --total                   total days ($opt_total)\n";
    print "    -e, --equity                  equity in 100M ($opt_equity)\n";
    print "    -p, --percent                 max ascending percent ($opt_percent)\n";
    print "    -d, --database                database path [$opt_path]\n";
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
sub delta_total;
sub main;

find( \&find_name, "$opt_path" ); 

main();

sub main
{
    foreach my $stock (@stock_array)
    {
        my %ret = do_work $stock;
        
        if( !$ret{'return'} )
        {
            print "$stock,$ret{'total'},";
            printf "%d,", $ret{'equity'} / $CONST_100M;
            printf "%.2f\n", $ret{'percent'};
        }
    }
}

sub do_work
{
    my ($stock) = @_;
    my %ret;
    my @database;
    my $filename_txt = "$opt_path/$stock.csv";
    
    $ret{'return'} = -1;
    
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
            
            push @database, \%one_day;
        }
    }
    
    close FH;
    
    $ret{'total'} = scalar @database;
    return %ret  if( $ret{'total'} > $opt_total || $ret{'total'} == 0 );
    
    my $p_last = $database[@database - 1];
    $ret{'equity'} = $p_last->{'equity'} * $p_last->{'close'};
    return %ret  if( $ret{'equity'} > $opt_equity * $CONST_100M );
    
    my $delta = delta_total \@database;
    $ret{'percent'} = $delta;
    return %ret  if( $delta > $opt_percent );
    
    $ret{'return'} = 0;
    return %ret;
}

sub delta_total
{
    my ($p_database) = @_;
    my $p_first = $p_database->[0];
    my $start = $p_first->{'close'};
    my $total = @$p_database > $opt_total ? $opt_total : @$p_database;
    my $end = 0.0;
    
    foreach my $i (1..$total)
    {
        my $p_last = $p_database->[@$p_database - $i];
        
        if( $p_last->{'close'} > $end )
        {
            $end = $p_last->{'close'};
        }
    }
    
    return ($end - $start) / $start;
}
