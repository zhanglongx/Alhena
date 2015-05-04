#! /usr/bin/perl -w

$ALHENA = "../bin/alhena";
$ALHENA_ARG = "-o no-upseri+fi -c pl-trade";
$CSV_PATH = defined($ARGV[0]) ? $ARGV[0] : "../bin/export";

sub trade
{
    my ($start, $profit, $loss) = @_;
    my @files = `find $CSV_PATH -name "*.csv"`;
    my $sum = 0;
    
    foreach $file (@files)
    {
        if( $file =~ m/[A-Za-z0-9]{8,8}\.csv/ )
        {
            my @exe_alhena = `$ALHENA $ALHENA_ARG --pl-trade-start $start --pl-trade-profit $profit --pl-trade-loss $loss $file`;
            
            foreach (@exe_alhena)
            {
                if( /^pl.*,.*,(.*)/ )
                {
                    my $delta = $1;
                 
                    $sum += $delta;
                }
            }
        }
    }
    
    return $sum;
}

my %best = ("best"=>0, "start"=>0, "profit"=>0, "loss"=>0);

foreach my $start (0..5)
{
    foreach my $profit (1..10)
    {
        foreach my $loss (1..15)
        {
            my $sum = trade $start, $profit, $loss;
    
            if( $sum < $best{"best"} )
            {
                $best{"best"}   = $sum;
                $best{"start"}  = $start;
                $best{"profit"} = $profit;
                $best{"loss"}   = $loss;
            }
        }
    }
}

printf "best: %.2f, start: %.2f, profit: %.2f, loss: %.2f\n", 
        $best{"best"}, $best{"start"}, $best{"profit"}, $best{"loss"};
