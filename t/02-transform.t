use Test::Most import => ['!pass'];
use IPC::Run qw(start pump finish timeout);
use Env::Path;
use Try::Tiny;

plan skip_all => 'transformator is required for this test' unless Env::Path->PATH->Whence('transformator');

plan tests => 1;

my $sock = './socket';
unlink $sock if -e $sock;

my ($in, $out, $err);
my $server = start [ transformator => $sock ], \$in, \$out, \$err, timeout(10);

pump $server until $out =~ /server bound/;

{
    package Webservice;
    use Dancer;
    use Dancer::Plugin::Transformator;

	set views => 't/views';	

	set plugins => {
		Transformator => {
			connect => $sock,
		}
	};

    get '/foo' => sub {
		transform_output jade => { name => 'Peter' };
		transform_output 'minify_html';
		return template 'transform';
	};

}

use Dancer::Test;

my ($R);

$R = dancer_response(GET => '/foo');
is($R->{content} => '<html><body><span>Hi Peter!</span><script>(function(){var n;n=function(){return 2.5}}).call(this);</script>');

diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{read_logs()};

$server->kill_kill;
finish $server;

done_testing;
