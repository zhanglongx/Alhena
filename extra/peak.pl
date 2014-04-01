#! /usr/bin/perl -w

my @max_cnt;
my @min_cnt;

my $g_total;

while(<>)
{
    my $max;
    my $min;
    
    if( /^stat,.*,.*,(.*),.*,(.*),.*/ )   
    {
        $max = $1;
        $min = $2;
        
        if( $max <= 0.0 )
        {
            $max_cnt[0]++;
        }
        elsif ( $max > 0.0 && $max <= 0.05 )
        {
            $max_cnt[1]++;
        }
        elsif ( $max > 0.05 && $max <= 0.10 )
        {
            $max_cnt[2]++;
        }
        else
        {
            $max_cnt[3]++;
        }
        
        if( $min <= -0.20 )
        {
            $min_cnt[0]++;
        }
        elsif ( $min > -0.20 && $min <= -0.10 )
        {
            $min_cnt[1]++;
        }
        elsif ( $min > -0.10 && $min <= -0.0 )
        {
            $min_cnt[2]++;
        }
        else
        {
            $min_cnt[3]++;
        }
                
        $g_total++;
    }
}

print "total: $g_total\n";

print "max: ";
foreach my $max (@max_cnt)
{
    $max = $max/$g_total * 100;
    
    printf "%.2f  ", $max;
}

print "\n";

print "min: ";
foreach my $min (@min_cnt)
{
    $min = $min/$g_total * 100;
    
    printf "%.2f  ", $min;
}

print "\n";
