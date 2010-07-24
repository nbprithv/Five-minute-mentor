package hackday2010::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

hackday2010::View::TT - TT View for hackday2010

=head1 DESCRIPTION

TT View for hackday2010.

=head1 SEE ALSO

L<hackday2010>

=head1 AUTHOR

niranjan,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
