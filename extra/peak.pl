#! /usr/bin/perl -w

my @max_ref  = ( .20, .10, .05, .0 );
my @max_cnt1 = ( 0, 0, 0, 0, 0 );
my @max_cnt2 = ( 0, 0, 0, 0, 0 );

my @min_ref = ( -0.0, -0.05, -0.10, -0.20 );
my @min_cnt = ( 0, 0, 0, 0, 0 );

my $g_total = 0;

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

while(<>)
{
    my $max1;
    my $min;
    my $max2;
    
    if( /^stat,.*,.*,(.*),(.*),(.*),(.*),(.*),(.*)/ )   
    {
        $max1 = $1;
        $min  = $3;
        $max2 = $5;
        
        #print "$max, $max_day, $min, $min_day\n";
        
        count_number( \@max_ref, \@max_cnt1, $max1 );
        
        count_number( \@min_ref, \@min_cnt, $min );
        
        count_number( \@max_ref, \@max_cnt2, $max2 );
        
        $g_total++;
    }
}

$g_total > 0 or die;

print "total: $g_total\n";

print_number( "max1", \@max_ref, \@max_cnt1, $g_total );

print_number( "min", \@min_ref, \@min_cnt, $g_total );

print_number( "max2", \@max_ref, \@max_cnt2, $g_total );
