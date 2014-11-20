package Dancer::Plugin::Transformator;

use strict;
use warnings;
use Dancer ':syntax';
use Dancer::Plugin;
use Net::NodeTransformator;

=head1 NAME

Dancer::Plugin::Transformator - Dancer plugin for Net::NodeTransformator

=head1 VERSION

Version 0.100

=cut

our $VERSION = '0.100';
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

=head1 DESCRIPTION	

This plugin provides two methods to interact with L<Net::NodeTransformator>.

=head1 PLUGIN CONFIGURATION

The plugin needs only one setting, the C<connect> parameter. See documentation of L<Net::NodeTransformator> for more information about the syntax.

=head1 METHODS

=head2 C<< transform($engine, $input[, $data]) >>

A wrapper method for L<Net::NodeTransformator>::transform.

=cut

register transform => sub {
	my ($engine, $input, $data) = @_;
	my $config = plugin_setting;
	my $nnt = Net::NodeTransformator->new($config->{connect});
	$nnt->transform($engine, $input, $data);
};

=head2 C<< transform_output($engine[, $data]) >>

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

=head1 AUTHOR

David Zurborg, C<< <zurborg@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through my project management tool
at L<projects//issues/new>.  I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Transformator

You can also look for information at:

=over 4

=item * GitHub: Public repository of this module

L<https://github.com/zurborg/libdancer-plugin-transformator-perl>

=back

=head2 SEE ALSO

=over 4

=item L<Net::NodeTransformator>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2014 David Zurborg, all rights reserved.

This program is released under the following license: ISC

=cut

1;
