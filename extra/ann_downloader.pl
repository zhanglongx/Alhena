use strict;
use warnings;

use LWP::UserAgent;

use JSON;

sub get_url
{
    my ($stock) = @_;

    my $url = 'http://www.cninfo.com.cn/cninfo-new/announcement/query';
    
    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");
    $ua->timeout(120);
   
    my $res;
    my $content;
    
    $res = $ua->post( $url, { 'stock'    => "$stock",
                              'category' => 'category_ndbg_szsh',
                              'pageSize' => '50',
                              'tabName'  => 'fulltext' });

    $content = $res->decoded_content;                     

    return $content;
}

sub main;

main;

sub main
{
    my $content = get_url 000651;

    $content =~ /{.*}/;
    my $data = decode_json($&);

    for my $p_entry (@{$data->{announcements}})
    {
        print $p_entry->{announcementTitle};
        print "\n";
    }
}
