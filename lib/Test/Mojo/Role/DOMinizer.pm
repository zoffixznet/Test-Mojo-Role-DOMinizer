package Test::Mojo::Role::DOMinizer;

use Mojo::Base -base;
use Role::Tiny;

# VERSION

sub in_DOM {
    my ($self, $code) = @_;
    my $res = do {
        local $_ = $self->tx->res->dom;
        $code->($_, $self);
    };

    # Don't know a better way to test whether the returned object is
    # a Test::Mojo when it does arbitrary roles, so doing this hack:
    my $ref = ref $res;
    $ref && (
        $ref eq 'Test::Mojo' or $ref =~ /^Test::Mojo__WITH__Test::Mojo::Role/
    ) ? $res : $self
}

1;
__END__

=encoding utf8

=for stopwords Znet Zoffix app DOM

=head1 NAME

Test::Mojo::Role::DOMinizer - Test::Mojo role to examine DOM mid test chain

=head1 SYNOPSIS

=for pod_spiffy start code section

    use Test::More;
    use Test::Mojo::WithRoles 'DOMinizer';
    my $t = Test::Mojo::WithRoles->new('MyApp');

    $t  ->get_ok('/foo')

        # in-chain access to current DOM via $_:
        ->in_DOM(sub { is $_->find('.foo')->size, $_->find('.bar')->size })

        # current Test::Mojo object is also passed as second arg:
        ->in_DOM(sub {
            my ($dom, $t) = @_;
            for my $id ($dom->find('.stuff .id')->map('all_text')->each) {
                $t = $t->get_ok("/stuff/for/$id")->status_is(200);
            }
            $t
        })

        # Returning a Test::Mojo object from sub makes it the 
        # return value of in_DOM, otherwise, the original one is used:
        ->in_DOM(sub {
            # (example `click_ok` method is from Test::Mojo::Role::SubmitForm)
            $_[1]->click_ok('.config-form' => {
                $_->find('[name^=is_notify_]"')
                    ->map(sub { $_->{name} => 1 })->each
            })
        })
        ->get_ok('/w00t');

    done_testing;

=for pod_spiffy end code section

=head1 DESCRIPTION

Write long chains of L<Test::Mojo> methods manipulating the
pages and doing tests on them is neat. Often, contents of the page
inform what the following tests will do. This requires breaking the chain,
writing a few calls to get to the DOM, then save stuff into widely-scoped
variables.

This module offers part stylistic, part functional alternative to facilitate
such testing. All the DOM wrangling is done in-chain, and it comes handily
aliased to C<$_>, readily available.

=head1 METHODS

The role provides these methods:

=head2 C<in_DOM>

Dive into the a section utilizing DOM:

    $t  ->get_ok('/foo')
        ->in_DOM(sub { is $_->find('.foo')->size, $_->find('.bar')->size })
        ->get_ok('/bar')
        ->in_DOM(sub { my ($dom, $current_test_mojo) = @_; })

The idea is this method lets extract something from the DOM to perform
some testing and then continue on with your regular chain of
L<Mojo::Test> tests.

Takes a sub ref as the argument. The first argument the sub
receives is L<Mojo::DOM> object representing current DOM of the test. It is
also available via the C<$_> variable. The second positional argument
is the the currently used L<Mojo::Test> object.

If returned value from the sub is a L<Mojo::Test> object, it will used as the
return value of the method. Otherwise, the original L<Mojo::Test> object
the method was called on will be used. Essentially this means you can ignore
what you return from the sub.

The call to C<in_DOM> does not perform any tests in itself, so
don't count it towards total number of tests run.

=head1 SEE ALSO

L<Test::Mojo>, L<Mojo::DOM>

=for pod_spiffy hr

=head1 REPOSITORY

=for pod_spiffy start github section

Fork this module on GitHub:
L<https://github.com/zoffixznet/Test-Mojo-Role-DOMinizer>

=for pod_spiffy end github section

=head1 BUGS

=for pod_spiffy start bugs section

To report bugs or request features, please use
L<https://github.com/zoffixznet/Test-Mojo-Role-DOMinizer/issues>

If you can't access GitHub, you can email your request
to C<bug-test-mojo-role-DOMinizer at rt.cpan.org>

=for pod_spiffy end bugs section

=head1 AUTHOR

=for pod_spiffy start author section

=for pod_spiffy author ZOFFIX

=for pod_spiffy end author section

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut

