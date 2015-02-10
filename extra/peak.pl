#! /usr/bin/perl -w

while(<>)
{
    my $filename = $ARGV;
    
    $filename =~ m/([a-zA-Z]+[0-9]+)/;
    $filename = $1;
    
    if( /^stat.*/ )
    {
        print "$filename,";
        print;
    }
}
