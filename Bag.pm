package Set::Bag;

# $Id: Bag.pm,v 1.7 1998/10/04 18:45:06 jhi Exp jhi $

$VERSION = 1.002;

=pod

=head1 NAME

    Set::Bag - bag (multiset) class

=head1 SYNOPSIS

    use Set::Bag;

    my $bag_a = Set::Bag->new(apples => 3, oranges => 4);
    my $bag_b = Set::Bag->new(mangos => 3);
    my $bag_c = Set::Bag->new(apples => 1);
    my $bag_d = ...;
    
    # Methods

    $bag_b->insert(apples => 1);
    $bag_b->remove(mangos => 1);

    $bag_b->insert(cherries => 1, $bag_c);

    my @b_elements = $bag_b->elements;	# ('apples','cherries','mangos')
    my @a_grab_all = $bag_a->grab;	# (apples => 3, oranges => 4)
    my @b_grab_app = $bag_b->grab('apples', 'cherries'); # (3, 1)

    print "bag_a     sum      bag_b = ", $bag_b->sum($bag_b),          "\n";
    print "bag_a    union     bag_b = ", $bag_a->union($bag_b),        "\n";
    print "bag_a intersection bag_b = ", $bag_a->intersection($bag_b), "\n";

    print "bag_b complement = ", $bag_b->complement, "\n";

    # Operator Overloads

    print "bag_a = $bag_a\n";		# (apples => 3, oranges => 4)

    $bag_b += $bag_c;					# Insert
    $bag_b -= $bag_d;					# Remove

    print "bag_b = $bag_b\n";

    print "bag_a + bag_b = ", $bag_b + $bag_b, "\n";	# Sum
    print "bag_a | bag_b = ", $bag_a | $bag_b, "\n";	# Union
    print "bag_a & bag_b = ", $bag_a & $bag_b, "\n";	# Intersection

    $bag_b |= $bag_c;					# Maximize
    $bag_b &= $bag_d;					# Minimize

    print "good\n" if     $bag_a eq "(apples => 3, oranges => 4)";	# Eq
    print "bad\n"  unless $bag_a ne "(apples => 3, oranges => 4)";	# Ne

    print "-bag_b = ", -$bag_b"\n";			# Complement

    $bag_c->remove(apples => 5);			# Would abort.
    print "Can",					# Cannot ...
          $bag_c->over_remove() ? "" : "not",
          " over remove from bag_c\n";
    $bag_c->over_remove(1);
    print "Can",					# Can ...
          $bag_c->over_remove() ? "" : "not",
          " over remove from bag_c\n";
    $bag_c->remove(apples => 5);			# Would succeed.
    print $bag_c, "\n";					# ()

=head1 DESCRIPTION

This module implements a simple bag (multiset) class.

A bag may contain one or more instances of elements.  One may add and
remove one or more instances at a time.

If one attempts to remove more instances than there are to remove
from, the default behavious of B<remove> is to abort.  The
B<over_remove> can be used to control this behaviour.

Inserting or removing negative number of instances translates into
removing or inserting positive number of instances, respectively.

The B<sum> is something called the I<additive union>.  It leaves in
the result bag the sum of all the instances of all bags.

The B<union> is something called the I<maximal union>.  It leaves in
the result bag the maximal number of instances in all bags.

The B<intersection> leaves in the result bag only the elements that
have instances in all bags and of those the minimal number of instances.

The B<complement> will leave in the result bag the maximal number of
instances ever seen (via B<new>, B<insert>, B<sum>, or B<maximize>)
minus the number of instances in the complemented bag.

Note the low precedence of C<|> and C<&> compared with C<eq> and C<ne>.

=head1 AUTHOR

Jarkko Hietaniemi <jhi@iki.fi>

=head1 COPYRIGHT

O'Reilly and Associates.  This module can be distributed under the
same terms as Perl itself.

=cut

require 5.004;
use strict;
use overload
    q("")  => \&bag,
    q(eq)  => \&eq,
    q(ne)  => \&ne,
    q(+=)  => \&insert,
    q(-=)  => \&remove,
    q(+)   => \&sum,
    q(-)   => \&difference,
    q(|=)  => \&maximize,
    q(&=)  => \&minimize,
    q(|)   => \&union,
    q(&)   => \&intersection,
    q(neg) => \&complement,
    q(=)   => \&copy,
    ;

sub new {
    my $type = shift;
    my $bag = { };
    bless $bag, $type;
    $bag->insert(@_);
    return $bag;
}

sub elements {
    my $bag = shift;
    return sort keys %{$bag};
}

sub bag {
    my $bag = shift;
    return
	"(" .
	(join ", ",
             map { "$_ => $bag->{$_}" }
                 sort grep { ! /^Set::Bag::/ } $bag->elements) .
	")";
}

sub eq {
    return $_[2] ? "$_[1]" eq $_[0] : "$_[0]" eq $_[1];
}

sub ne {
    return not $_[0] eq $_[1];
}

sub grab {
    my $bag = shift;
    if (@_) {
      my @grab = @{$bag}{@_};
      return map { defined $_ ? $_ : 0 } @grab;
    } else {
      return %{$bag};
    }
}

sub _merge {
    my $bag     = shift;
    my $sub     = shift; # Element subroutine.
    my $ref_arg = shift; # Argument list.
    my $ref_bag = ref $bag;
    while (@{$ref_arg}) {
        my $e = shift @{$ref_arg};
        if (ref $e eq $ref_bag) {
            foreach my $c ($e->elements) {
                $sub->($bag, $c, $e->{$c});
            }
        } else {
            $sub->($bag, $e, shift @{$ref_arg});
        }
    }
}

sub _underload { # Undo overload effects on @_.
    # If the last argument looks like it might be
    # residue of the operator overload system, drop it.
    pop @{$_[0]}
        if (not defined $_[0]->[-1] and not ref $_[0]->[-1]) or
	   $_[0]->[-1] eq '';
}

my %universe;

sub _insert {
    my ($bag, $e, $n) = @_;
    $bag->{$e} += int $n;
    $universe{$e} = $bag->{$e}
        if $bag->{$e} > ($universe{$e} || 0);
}

my $over_remove = 'Set::Bag::__over_remove__';

sub over_remove {
    my $bag = shift;

    if (@_ == 1) {
	$bag->{$over_remove} = shift;
    } elsif (@_ == 0) {
	return ($bag->{$over_remove} ||= 0);
    } else {
	die "Set::Bag::over_remove: too many arguments (",
	    $#_+1,
	    "), want 0 or 1\n";
    }
}

sub _remove {
    my ($bag, $e, $n) = @_;

    unless ($bag->over_remove) {
	my $m = $bag->{$e} || 0;
	$m >= $n or
	    die "Set::Bag::remove: '$e' $m < $n\n";
    }
    $bag->{$e} -= int $n;
    delete $bag->{$e} if $bag->{$e} < 1;
}


sub insert {
    _underload(\@_);
    my $bag = shift;
    $bag->_merge(sub { my ($bag, $e, $n) = @_;
		       if ($n > 0) {
			   $bag->_insert($e, $n);
		       } elsif ($n < 0) {
			   $bag->_remove($e, -$n);
		       } },
		 \@_);
    return $bag;
}

sub remove {
    _underload(\@_);
    my $bag = shift;
    $bag->_merge(sub { my ($bag, $e, $n) = @_;
		      if ($n > 0) {
			  $bag->_remove($e, $n);
		      } elsif ($n < 0) {
			  $bag->_insert($e, -$n);
		      } },
		\@_);
    return $bag;
}

sub maximize {
    _underload(\@_);
    my $max = shift;
    $max->_merge(sub { my ($bag, $e, $n) = @_;
		      $bag->{$e} = $n
			  if not defined $bag->{$e} or $n > $bag->{$e};
		      $universe{$e} = $n
		              if $n > ($universe{$e} || 0) },
		\@_);
    return $max;
}

sub minimize {
    _underload(\@_);
    my $min = shift;
    my %min;
    foreach my $e ($min->elements) { $min{$e} = 1 }
    $min->_merge(sub { my ($bag, $e, $n) = @_;
		      $min{$e}++;
		      $bag->{$e} = $n
			  if defined $bag->{$e} and $n < $bag->{$e} },
		\@_);
    foreach my $e (keys %min) { delete $min->{$e} if $min{$e} == 1 }
    return $min;
}

sub copy {
    my $bag = shift;
    return (ref $bag)->new($bag->grab);
}

sub sum {
    my $union = (shift)->copy;
    $union->insert(@_);
    return $union;
}

sub difference {
    my $difference = (shift)->copy;
    $difference->remove(@_);
    return $difference;
}

sub union {
    my $union = (shift)->copy;
    $union->maximize(@_);
    return $union;
}

sub intersection {
    my $intersection = (shift)->copy;
    $intersection->minimize(@_);
    return $intersection;
}

sub complement {
    my $bag = shift;
    my $complement  = (ref $bag)->new;
    foreach my $e (keys %universe) {
	$complement->{$e} = $universe{$e} - ($bag->{$e} || 0);
	delete $complement->{$e} unless $complement->{$e};
    }
    return $complement;
}

1;
