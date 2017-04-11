#! /usr/bin/perl -w

use strict;
use warnings;

use utf8;
binmode STDOUT, ":utf8";

use LWP::UserAgent;
use LWP::Simple;
use Getopt::Long;

use JSON;

my $MAX_PER_PAGE = 50;
my $opt_help=0;
my $opt_debug=0;
#my $opt_path="/home/zhlx/OneDrive/FI.Advanced/年报";
my $opt_path="/Users/zhanglongxiao/Workdir/announce";

GetOptions( "help"         => \$opt_help,
            "debug"        => \$opt_debug,
            "path=s"       => \$opt_path,
           );

if( $opt_help )
{
    print "$0 [options] stock\n";
    print "    -h, --help                    print this message\n";
    print "    -d, --debug                   debug mode(no download)\n";
    print "    -p, --path                    download path [$opt_path]\n";
    exit(0);
}

# FIXME: add database stock check
(-d $opt_path) or die "$opt_path does not exist\n";

sub get_url
{
    my ($stock, $page) = @_;

    my $url = 'http://www.cninfo.com.cn/cninfo-new/announcement/query';
    
    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");
    $ua->timeout(120);
   
    my $res;
    my $content;
    
    $res = $ua->post( $url, { 'stock'    => "$stock",
                              'category' => 'category_ndbg_szsh',
                              'pageSize' => '$MAX_PER_PAGE',
                              'tabName'  => 'fulltext',
                              'pageNum'  => "$page",
                            });

    $content = $res->decoded_content;                     

    return $content;
}

sub is_announce;
sub is_folder_empty;
sub mkdir_stock;
sub get_one;
sub main;

main;

sub main
{
    my @stock_all = @ARGV;

    for my $stock (@stock_all)
    {
        get_one $stock;
    }
}

sub is_announce
{
    my ($title) = @_;
    my @excludes = ( '指标', '摘要', '取消', '英文' );

    Encode::_utf8_on($title);

    for my $keyword (@excludes)
    {
        Encode::_utf8_on($keyword);
        if( index( $title, $keyword ) >= 0 )
        {
            return 0;
        }
    }

    return 1;
}

sub is_folder_empty
{
    my $dirname = shift;
    opendir(my $dh, $dirname) or return 0;
    return scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0;
}

sub mkdir_stock
{
    my ($stock) = @_;
    my $dir = "$opt_path/$stock";

    if( -d $dir )
    {
        unless( is_folder_empty $dir )
        {
            warn "$dir is not empty\n";
            return 1;
        }
    }

    mkdir $dir or die "creating $dir failed, $!\n";
    return 1;
}

sub get_one
{
    my ($stock) = @_;
    my $down_pre = 'http://www.cninfo.com.cn/';

    return  unless( $opt_debug || mkdir_stock $stock );

    for my $page (1..100)
    {
        my $content = get_url( $stock, $page );

        $content =~ /{.*}/;
        my $data = decode_json($&);

        print "$content\n"  if( $opt_debug );
        
        for my $p_entry (@{$data->{announcements}})
        {
            my $title = $p_entry->{announcementTitle};
            my $name  = $p_entry->{secName};
            my $url   = "$down_pre$p_entry->{adjunctUrl}";

            if( $opt_debug )
            {
                print "$title\n$url\n";
                next;
            }

            next  unless( $url =~ /\.pdf$/i );
            next  unless( is_announce( $title ) );
            next  unless( $title =~ /\d{4,4}/ );

            my $year = $&;
            my $file = "$opt_path/$stock/$stock.$name.$year.pdf";

            # cowardly skip
            next  if( -e "$opt_path/$stock/$stock.$name.$year.pdf" );

            getstore( $url, $file );
        }

        last  unless( @{$data->{announcements}} );
    }
}
