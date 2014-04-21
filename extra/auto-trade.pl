#! /usr/bin/perl -w

$ALHENA = "../bin/alhena";
$ALHENA_ARG = "-o no-upseri+fi -c pl-trade";
$CSV_PATH = defined($ARGV[0]) ? $ARGV[0] : "../bin/export";

sub trade
{
    my ($profit, $loss) = @_;
    my @files = `find $CSV_PATH -name "*.csv"`;
    my $sum = 0;
    
    foreach $file (@files)
    {
        if( $file =~ m/[A-Za-z0-9]{8,8}\.csv/ )
        {
            my @exe_alhena = `$ALHENA $ALHENA_ARG --pl-trade-profile $profit --pl-trade-loss $loss $file`;
            
            foreach (@exe_alhena)
            {
                if( /^pl.*,.*,(.*)/ )
                {
                    my $profit = $1;
                 
                    $sum += $profit;
                }
            }
        }
    }
    
    return $sum;
}

my %best = ("best"=>0, "profit"=>0, "loss"=>0);

foreach $profit (1..10)
{
    foreach $loss (1..10)
    {
        my $sum = trade $profit, $loss;

        if( $sum < $best{"best"} )
        {
            $best{"best"}   = $sum;
            $best{"profit"} = $profit;
            $best{"loss"}   = $loss;
        }
    }
}

printf "best: %.2f, profit: %.2f, loss: %.2f\n", $best{"best"}, $best{"profit"}, $best{"loss"};

=pod
sub count_number {
    my ($p_ref, $p_cnt, $value ) = @_;
    my $ref_num = scalar @$p_ref;
    
    foreach my $i (0..$ref_num-1)
    {
        if( $value > $$p_ref[$i] )
        {
            #print "$value $$p_ref[$i]\n";
            
            $$p_cnt[$i]++;
            return;
        }
    }
    
    $$p_cnt[$ref_num]++;
}

sub print_number{
    my ($name, $p_ref, $p_cnt, $total ) = @_;
    
    $total > 0 or die;
    
    print( "$name\n" );
    
    foreach my $v (@$p_ref)
    {
        printf "%.2f\t", $v;
    }
    
    print"\n";
    
    foreach my $v (@$p_cnt)
    {
       $v = $v / $total * 100;
        
        printf "%.2f\t", $v;
    }
    
    print "\n";
}

sub stat_count {
    my ($p_stat, $value) = @_;
    
    $$p_stat{"cnt"}++;
    $$p_stat{"sum"} += $value;
    $$p_stat{"square"} += $value * $value;
}

sub stat_sum {
    my $p_stat = $_[0];
    my $cnt = $$p_stat{"cnt"};
    
    return if( $$p_stat{"cnt"} == 0 );
    
    $$p_stat{"expect"} = $$p_stat{"sum"} / $cnt;
    $$p_stat{"var"}    = $$p_stat{"square"} / $cnt 
                       - $$p_stat{"expect"} * $$p_stat{"expect"};
                       
    $$p_stat{"var"} = -1 * $$p_stat{"var"} if ( $$p_stat{"var"} < 0 );
    
    $$p_stat{"var"} = sqrt $$p_stat{"var"};
}

sub stat_print {
    my ($name, $p_stat) = @_;
    
    my $expect = $$p_stat{"expect"};
    my $var    = $$p_stat{"var"};
    
    print "$name  ";
    printf "expection: %.3f, variance: %.3f\n", $expect, $var;
}

while(<>)
{
    if( /^stat,.*,(.*),(.*),(.*),(.*),(.*),(.*),(.*)/ )   
    {
        my $b_is_open_high = $1;
        
        my $max1 = $2;
        my $min  = $4;
        my $max2 = $6;
        
        my $max1_day = $3;
        my $min_day  = $5;
        
        #print "$max, $max_day, $min, $min_day\n";
        
        if( $b_is_open_high != 1 ) # $b_is_open_high != 1
        {
            count_number( \@max_ref, \@max_cnt1, $max1 );
            count_number( \@min_ref, \@min_cnt, $min );
            count_number( \@max_ref, \@max_cnt2, $max2 );
            
            stat_count( \%max1_sum, $max1 );
            stat_count( \%min_sum,  $min );
            stat_count( \%max2_sum, $max2 );
            
            stat_count( \%max1_day_sum, $max1_day );
            stat_count( \%min_day_sum,  $min_day );
            
            $g_total++;
        }
    }
}

stat_sum( \%max1_sum );
stat_sum( \%min_sum );
stat_sum( \%max2_sum );

stat_sum( \%max1_day_sum );
stat_sum( \%min_day_sum );

stat_print( "max1", \%max1_sum );
stat_print( "min",  \%min_sum  );
stat_print( "max2", \%max2_sum );

stat_print( "max1 day", \%max1_day_sum );
stat_print( "min day", \%min_day_sum );

$g_total > 0 or die;

print "total: $g_total\n";

print_number( "max1", \@max_ref, \@max_cnt1, $g_total );
print_number( "min", \@min_ref, \@min_cnt, $g_total );
print_number( "max2", \@max_ref, \@max_cnt2, $g_total );
=cut