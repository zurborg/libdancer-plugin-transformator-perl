use Test::Most import => ['!pass'];
use Net::NodeTransformator;

plan skip_all => 'transformator is required for this test' unless Env::Path->PATH->Whence('transformator');

plan tests => 3;

my $server = Net::NodeTransformator->standalone;
ok $server;

my $socket = $server->{host}.':'.$server->{port};
ok $socket;

{
    package Webservice;
    use Dancer;
    use Dancer::Plugin::Transformator;

	set views => 't/views';	

	set plugins => {
		Transformator => {
			connect => $socket,
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

$server->cleanup;

done_testing;
