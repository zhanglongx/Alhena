#! perl -w

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
my $opt_path="../bin/export";

GetOptions( "help"        => \$opt_help,  
            "name=s"      => \$opt_name,
            "start=s"     => \$opt_start,
            "backward=i"  => \$opt_backward,
            "forward=i"   => \$opt_forward,
            "path=s"      => \$opt_path,
           );
           
if( $opt_help || !defined($opt_name) )
{
    print "data_printer [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -n, --name <name>             specifiy the subject\n";
    print "    -s, --start <6/13/1970>       start date\n";
    print "    -b, --backward <-9>           backward search\n";
    print "    -f, --forward <32>            forward search\n";
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

sub fi
{
    my ($i_entry) = @_;
    my ($date2, , , ,$pclose2, $vol2) = @{$database[$i_entry]};
    
    return 0.0  if( !$i_entry );
        
    my ($date1, , , ,$pclose1, $vol1) = @{$database[$i_entry - 1]};
    
    return $pclose1;
}

sub print_data
{
    my ($i_entry) = @_;
    my ($date, $popen, $phigh, $plow, $pclose, $vol, $mount) = @{$database[$i_entry]};
    my $pfi = fi($i_entry);
    
    print "$date, $popen, $phigh, $plow, $pclose, $vol, $pfi\n";
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

($i_start || $i_end) or exit(1);

foreach my $i_entry ($i_start..$i_end)
{
    print_data $i_entry;
}
