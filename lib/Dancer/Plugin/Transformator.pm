use strict;
use warnings;
package Dancer::Plugin::Transformator;
# ABSTRACT: Dancer plugin for Net::NodeTransformator

use Dancer ':syntax';
use Dancer::Plugin;
use Net::NodeTransformator;

# VERSION
our $CLASS = __PACKAGE__;

=head1 SYNOPSIS

	use Dancer::Plugin::Transformator;
	
	set plugins => {
		Transformator => {
			connect => 'localhost:12345',
		}
	};
	
	get '/' => sub {
		transform_output 'jade';
		transform_output 'minify_html';
		return template 'index';
	};

=head1 PLUGIN CONFIGURATION

The plugin needs only one setting, the C<connect> parameter. See documentation of L<Net::NodeTransformator> for more information about the syntax.

=method C<< transform($engine, $input[, $data]) >>

A wrapper method for L<Net::NodeTransformator>::transform.

=cut

register transform => sub {
	my ($engine, $input, $data) = @_;
	my $config = plugin_setting;
	my $nnt = Net::NodeTransformator->new($config->{connect});
	$nnt->transform($engine, $input, $data);
};

=method C<< transform_output($engine[, $data]) >>

Creates an after-hook and transform the response content via specified engine. Multiple calls of this method causes the engines to be chained. In the synopsis example above, the content of the template output is first transformed via I<jade> and then minified. The argument C<$data> is only meaningful for I<jade> engine.

=cut

register transform_output => sub {
	my ($engine, $data) = @_;
	var $CLASS = [] unless exists vars->{$CLASS};
	push @{vars->{$CLASS}} => { engine => $engine, data => $data };
};

hook after => sub {
	my $response = shift;
	if (exists vars->{$CLASS}) {
		my $config = plugin_setting;
		my $nnt = Net::NodeTransformator->new($config->{connect});
		my $transforms = delete vars->{$CLASS};
		foreach my $transform (@$transforms) {
			$response->content($nnt->transform($transform->{engine}, $response->content, $transform->{data}));
		}
	}
};

register_plugin;

=head2 SEE ALSO

=over 4

=item * L<Net::NodeTransformator>

=back

1;
