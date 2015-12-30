package alhena_database;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = qw(parse_date delta_days_wrapper read_old write_new);
@EXPORT_OK   = qw(parse_date delta_days_wrapper read_old write_new);
%EXPORT_TAGS = ( DEFAULT => [qw(&read_old)],
                 Both    => [qw(&read_old)]);
                 
my $DATABASE_VERSION = 0.9;

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

sub read_old
{
    my ($stock, $path, $p_xdr_info, $p_daily) = @_;
    my $filename = "$path/$stock.csv";
    my $i_fails = 0;
    
    while( ! open FH, "$filename" )
    {
        if( $i_fails++ > 5 )
        {
            print "can't open $filename for read: $!\n";
            return 1;
        }
    }
    
    while(<FH>)
    {
        # version
        if( /^#\s+version:\s+(.*)/ )
        {
            my $csv_version = $1;
            if( $csv_version ne $DATABASE_VERSION )
            {
                warn 'version does not match: csv($csv_version) module($DATABASE_VERSION)\n';
                return 1;
            }
        }
        
        # xdr info
        if( /^#\s+(\d+-\d+-\d+),([.0-9]+),([.0-9]+),([.0-9]+)/ )
        {
            my %one_xdr;

            $one_xdr{'date'}     = $1;
            $one_xdr{'gift'}     = $2;
            $one_xdr{'donation'} = $3;
            $one_xdr{'bouns'}    = $4;
            
            $one_xdr{'new'}      = 0;
                        
            push @$p_xdr_info, \%one_xdr;
        }
        
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
            
            push @$p_daily, \%one_day;
        }
    }
    
    close FH;
    
    return 0;
}

sub write_new
{
    my ($stock, $path, $p_xdr_info, $p_daily) = @_;
    my $filename = "$path/$stock.csv";
    my $i_fails = 0;
    
    while( ! open WH, ">$filename" )
    {
        if( $i_fails++ > 5 )
        {
            print "can't open $filename for write: $!\n";
            return 1;
        }
    }
    
    print WH "# version: $DATABASE_VERSION\n";
        
    # start with xdr info
    foreach my $p_xdr (@$p_xdr_info)
    {
        my $date     = $p_xdr->{'date'};
        my $gift     = $p_xdr->{'gift'};
        my $donation = $p_xdr->{'donation'};
        my $bouns    = $p_xdr->{'bouns'};
        
        print WH "# $date,$gift,$donation,$bouns\n";
    }
    
    # follow daily
    foreach my $p_entry (@$p_daily)
    {
        my $date     = $p_entry->{'date'};
        my $f_open   = $p_entry->{'open'};
        my $f_high   = $p_entry->{'high'};
        my $f_low    = $p_entry->{'low'};
        my $f_close  = $p_entry->{'close'};
        my $i_vol    = $p_entry->{'vol'};
        my $i_equity = $p_entry->{'equity'};
        
        print WH "$date,";
        printf WH "%.2f,%.2f,%.2f,%.2f,%d,%d\n",
                  $f_open, $f_high, $f_low, $f_close, $i_vol, $i_equity;
    }
    
    close WH;
    return 0;
}