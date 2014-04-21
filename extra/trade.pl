#! /usr/bin/perl -w

my %profit_sum = (
        "sum"    => 0,
        "cnt"    => 0,
    );

my $g_total = 0;

sub stat_count {
    my ($p_stat, $value) = @_;
    
    $$p_stat{"cnt"}++;
    $$p_stat{"sum"} += $value;
}

while(<>)
{
    if( /^pl.*,.*,(.*)/ )   
    {
        my $profit = $1;

        stat_count( \%profit_sum, $profit );
        
        $g_total++;
    }
}

$g_total > 0 && ($g_total == $profit_sum{"cnt"}) or die;

print "total: $g_total\n";
printf "profit sum: %.2f, avg: %.2f\n", $profit_sum{"sum"}, $profit_sum{"sum"} / $g_total ;
