#! /usr/bin/perl -w

use Getopt::Long;
use File::Find;
use File::Basename;

use HTTP::Date;
use Date::Calc;

my $opt_help;
my $opt_name;
my $opt_start;
my $opt_backward = 9;
my $opt_forward = 32;
my $opt_end;
my $opt_m4hst;
my $opt_path="../bin/export";

GetOptions( "help"        => \$opt_help,  
            "name=s"      => \$opt_name,
            "start=s"     => \$opt_start,
            "backward=i"  => \$opt_backward,
            "forward=i"   => \$opt_forward,
            "m4hst=s"     => \$opt_m4hst,
            "path=s"      => \$opt_path,
           );
           
if( $opt_help || !defined($opt_name) )
{
    print "data_printer [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -n, --name <name>             specifiy the subject\n";
    print "    -s, --start <6/13/1970>       start date\n";
    print "    -b, --backward <9>            backward search\n";
    print "    -f, --forward <32>            forward search\n";
    print "    -m, --m4hst <path>            m4 hst path\n";
    print "    -p, --path <path>             database path\n";
    
    exit(0);
}

sub parse_date_wrapper
{
    my ($date) = @_;
    
    $date =~ s#^(.*)/(.*)#$2/$1#;
    
    return HTTP::Date::parse_date( $date );
}

sub delta_days_wrapper
{
    my ($date1, $date2) = @_;
    
    my ($year1, $month1, $day1) = parse_date_wrapper( $date1 );
    my ($year2, $month2, $day2) = parse_date_wrapper( $date2 );
    
    return Date::Calc::Delta_Days( $year1, $month1, $day1, $year2, $month2, $day2 );
}

sub add_days_wrapper
{
    my ($date, $delta) = @_;
    my ($year, $month, $day) = parse_date_wrapper($date);
    
    ($year,$month,$day) = Date::Calc::Add_Delta_Days($year, $month, $day, $delta);
    
    return "$month/$day/$year";
}

$opt_start="6/13/1970"   if( !defined($opt_start) );
$opt_backward = -1 * $opt_backward;

my ($opt_year) = parse_date_wrapper($opt_start);
defined($opt_year) or die "start date input error\n";

$opt_end   = add_days_wrapper( $opt_start, $opt_forward );
$opt_start = add_days_wrapper( $opt_start, $opt_backward );
#print "$opt_start -- $opt_end\n";

my $data_filename;

sub find_datafile {
    
    my $file = fileparse( $File::Find::name );
    
    if( $file =~ m/^SH$opt_name\.csv/i )
    {
        $data_filename = "$opt_path/$file";
        #print $data_filename;
    }
}

find( \&find_datafile, "$opt_path" ); 

defined($data_filename) 
    or die "can't find datafile with name($opt_name) in path($opt_path)\n";

my @database;

sub find_entry_by_start
{
    my ($start) = @_;
    my $p_entry;
    my $i_entry=0;
    
    foreach $p_entry (@database)
    {
        my $date = (@$p_entry)[0];
        
        if( delta_days_wrapper($start, $date) >= 0 )
        {
            return $i_entry;
        }
        
        $i_entry++;
    }
    
    return undef;
}

sub find_entry_by_end
{
    my ($end) = @_;
    my $p_entry;
    my $i_entry=0;
    
    foreach $p_entry (@database)
    {
        my $date = (@$p_entry)[0];
        
        if( delta_days_wrapper($end, $date) >= 0 )
        {
            return $i_entry;
        }
        
        $i_entry++;
    }    
    
    return $i_entry >= @database? $i_entry-1 : $i_entry;
}

sub print_data
{
    my ($i_entry) = @_;
    my ($date, $popen, $phigh, $plow, $pclose, $vol, $mount) = @{$database[$i_entry]};
    
    $date =~ s#^(.*)/(.*)#$2/$1#;
    
    my ($year, $month, $day) = HTTP::Date::parse_date( $date );
    
    print "$year.$month.$day,$popen,$phigh,$plow,$pclose,$vol\n";
}

sub print_hst
{
    my ($wh, $i_entry) = @_;
    my ($date, $popen, $phigh, $plow, $pclose, $vol, $mount) = @{$database[$i_entry]};
    
    $date =~ s#^(.*)/(.*)#$2/$1#;
    
    print $wh pack("I", HTTP::Date::str2time($date));
    print $wh pack("I", 0);
    print $wh pack("d", $popen);
    print $wh pack("d", $phigh);
    print $wh pack("d", $plow);
    print $wh pack("d", $pclose);
    print $wh pack("I", $vol);
    print $wh pack("a16", "");
}

open FH, "$data_filename" or die "can't open datafile: $!";

while(<FH>)
{
    if( /(.*),(.*),(.*),(.*),(.*),(.*),(.*)/ )
    {
        my @entry = ($1, $2, $3, $4, $5, $6, $7);
        
        push @database, \@entry;
    }
}

close FH;

my $i_start = find_entry_by_start( $opt_start );
my $i_end   = find_entry_by_end( $opt_end );
my $b_hst_open = 0;

($i_start || $i_end) or exit(1);

foreach my $i_entry ($i_start..$i_end)
{
    if( defined($opt_m4hst) )
    {
        my $postfix = int rand(1000);
        my $hst_filename = "$opt_m4hst/${opt_name}h${postfix}1440.hst";
        
        if( !$b_hst_open )
        {
            open WH, ">$hst_filename" or die "can't open $hst_filename: $!";
            binmode WH;
            
            print WH pack("I", 401);
            print WH pack("a64", "(C)opyright 2015, Alhena data printer.");
            print WH pack("a12", "${opt_name}h${postfix}");
            print WH pack("I", 1440);   # period
            print WH pack("I", 5);      # digital
            print WH pack("I", 0);      # time sign
            print WH pack("I", 0);      # last sync
            print WH pack("a52", "");   # unused
            
            $b_hst_open = 1;
        }
        
        print_hst( \*WH, $i_entry );
    }
    else
    {
        print_data $i_entry;
    }
}

if( $b_hst_open )
{
    close WH;
}
