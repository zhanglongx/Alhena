#! /usr/bin/perl -w

my @max_cnt_good = (0, 0, 0, 0);
my @min_cnt_good = (0, 0, 0, 0);

my @max_cnt_bad  = (0, 0, 0, 0);
my @min_cnt_bad  = (0, 0, 0, 0);

my $g_total = 0;

while(<>)
{
    my $max;
    my $min;
    
    if( /^stat,.*,.*,(.*),(.*),(.*),(.*)/ )   
    {
        $max = $1;
        $max_day = $2;
        $min = $3;
        $min_day = $4;
        
        #print "$max, $max_day, $min, $min_day\n";
        
        if( $max_day < $min_day )
        {
            if( $max <= 0.0 )
            {
                $max_cnt_good[0]++;
            }
            elsif ( $max > 0.0 && $max <= 0.05 )
            {
                $max_cnt_good[1]++;
            }
            elsif ( $max > 0.05 && $max <= 0.10 )
            {
                $max_cnt_good[2]++;
            }
            else
            {
                $max_cnt_good[3]++;
            }
            
            if( $min > -0.0 )
            {
                $min_cnt_good[0]++;
            }
            elsif ( $min <= -0.0 && $min > -0.10 )
            {
                $min_cnt_good[1]++;
            }
            elsif ( $min <= -0.10 && $min > -20.0 )
            {
                $min_cnt_good[2]++;
            }
            else
            {
                $min_cnt_good[3]++;
            }
                    
            $g_total++;
        }
    }
}

$g_total > 0 or die;

print "total: $g_total\n";

print "max: ";
foreach my $max (@max_cnt_good)
{
    $max = $max/$g_total * 100;
    
    printf "%.2f  ", $max;
}

print "\n";

print "min: ";
foreach my $min (@min_cnt_good)
{
    $min = $min/$g_total * 100;
    
    printf "%.2f  ", $min;
}

print "\n";
