#! /usr/bin/perl -w
use strict;

use Getopt::Long;
use Date::Calc;
use File::Find;
use File::Basename;

my $opt_help;
my $opt_name;
my @opt_possessor;
my $opt_start="2007-1-1";
my $opt_end;
my $opt_path="../database";

GetOptions( "help"         => \$opt_help,
            "name=s"       => \$opt_name,
            "possessor=s"  => \@opt_possessor,
            "start=s"      => \$opt_start,
            "end=s"        => \$opt_end,
            "database=s"   => \$opt_path
           );

my $loc_year;

if( !defined( $opt_end ) )
{
    my ($loc_sec, $loc_min, $loc_hour, $loc_day, $loc_mon, $tmp_year) = localtime();
    
    $tmp_year += 1900;
    $loc_mon  += 1;
    
    $opt_end = "$tmp_year-$loc_mon-$loc_day";
    
    $loc_year = $tmp_year;
}

if( $opt_help || !defined( $opt_name ) || !@opt_possessor )
{
    print "holder_finder [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -n, --name                    stock name\n";
    print "    -p, --possessor               possessor\n";
    print "    -s, --start                   start day [$opt_start]\n";
    print "    -e, --end                     end day [$opt_end]\n";
    print "    -d, --database                database path [$opt_path]\n";
    exit(0);
}

(-e $opt_path && -e "$opt_path/holder") or die "input path error\n";

sub parse_date
{
    my ($date) = @_;
    
    if ( $date =~ m/(\d+)-(\d+)-(\d+)/ )
    {
        return ($1, $2, $3);
    }
    else
    {
        warn "$date is not in date format\n";
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

sub main;
sub read_txt;
sub find_holder;
sub sum_one_season;
sub read_csv;
sub daily_delta;

main();

sub main
{
    (delta_days_wrapper( $opt_start, $opt_end ) >= 0)
        or die "input date error\n";
        
    my %holders = read_txt;
    my @daily   = read_csv;
    my @results = find_holder %holders;
    
    foreach my $p_result (@results)
    {
        my $start_date = $p_result->{'start_date'};
        my $end_date   = $p_result->{'end_date'};
        my $period = delta_days_wrapper( $start_date, $end_date );
        
        my $value_delta = daily_delta( \@daily, $start_date, $end_date );
        
        if( !defined( $value_delta ) )
        {
            warn "$opt_name,$start_date to $end_date,Suspension?\n";
            next;
        }

        print "$opt_name,$start_date to $end_date,";
        printf "%.2f,", $p_result->{'delta_per'};
        printf "%d,%.2f\n", $period, $value_delta;
    }
}

sub read_txt
{
    my $filename = "$opt_path/holder/$opt_name.txt";
    my $i_fails = 0;
    my %holders;
    
    while( ! open FH, "$filename" )
    {
        if( $i_fails++ > 5 )
        {
            warn "can't open $filename for read: $!\n";
            return %holders;
        }
    }
    
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
        }
        else
        {
            next;
        }
        
        push @{$holders{$date}}, \%entry;
    }
    
    close FH;
    return %holders;
}

sub find_holder
{
    my (%holders) = @_;
    my @miles = ('12-31', '09-30', '06-30', '03-31');
    my ($last_vol, $last_per) = (0,0);
    my %result;
    my @a_results;
    
    # look backward to match a period have what we want
    for( my $year = $loc_year; $year >= 2007; $year-- )
    {
        foreach my $date (@miles)
        {
            my $day = "$year-$date";
            my ($sum_vol, $sum_per) = sum_one_season( $holders{$day}, @opt_possessor );
            
            (delta_days_wrapper( $day, $opt_end ) >= 0)  or next;
            
            if( delta_days_wrapper( $opt_start, $day ) < 0 )
            {
                # don't get any more
                $holders{$day} = undef;
            }
            
            if( !defined( $holders{$day} ) || !$sum_vol ) # no data at that day
            {
                if( defined( $result{'end_date'} ) )
                {
                    $result{'start_date'} = $day;
                    
                    # FIXME: what to do before $opt_start
                    $result{'delta_vol'} += $last_vol;
                    $result{'delta_per'} += $last_per;
                    
                    my %tmp = %result;
                    push @a_results, \%tmp;
                    
                    $result{'end_date'} = undef;
                }
                
                next;
            }
            
            if( !defined( $result{'end_date'} ) )
            {
                $result{'end_date'} = $day;
                
                $result{'delta_vol'} =
                $result{'delta_per'} = 0;

                ($last_vol, $last_per) = ($sum_vol, $sum_per);
            }
            
            $result{'delta_vol'} += $last_vol - $sum_vol;
            $result{'delta_per'} += $last_per - $sum_per;

            ($last_vol, $last_per) = ($sum_vol, $sum_per);
        }
    }
    
    #FIXME: may lose one slot data since very early year
    
    return @a_results;
}

sub sum_one_season
{
    my ($p_entries, @name) = @_;
    my $sum_vol = 0;
    my $sum_per = 0;
    
    return (0,0)   if( !defined( $p_entries ) );
    
    foreach my $p_entry (@$p_entries)
    {
        foreach my $one_name (@name)
        {
            if( index( $p_entry->{'name'}, $one_name ) >= 0 )
            {
                $sum_vol += $p_entry->{'vol'};
                $sum_per += $p_entry->{'percent'};
            }
        }
    }
    
    return ($sum_vol, $sum_per);
}

sub read_csv
{
    my $filename = "$opt_path/$opt_name.csv";
    my $i_fails = 0;
    my @daily;
    
    while( ! open FH, "$filename" )
    {
        if( $i_fails++ > 5 )
        {
            warn "can't open $filename for read: $!\n";
            return @daily;
        }
    }    
    
    while(<FH>)
    {
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
            
            push @daily, \%one_day;
        }
    }
    
    close FH;
    return @daily;
}

sub daily_delta
{
    my ($p_daily, $start, $end) = @_;
    my ($start_v, $end_v);
    my $max = 0;
    
    foreach my $p_one (@$p_daily)
    {
        my $date = $p_one->{'date'};
        
        (delta_days_wrapper( $start, $date ) > 0) or next;
        
        (delta_days_wrapper( $date, $end ) <= 85) or next;
        
        (delta_days_wrapper( $end, $date ) <= 85) or last;
        
        $start_v = $p_one->{'close'}  if( !defined($start_v) );
        
        $max = $p_one->{'close'} if( $p_one->{'close'} > $max );   
    }

    return defined($start_v) ? (0, ($max - $start_v) / $start_v) : undef;
}
