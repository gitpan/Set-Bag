use Set::Bag;

use strict;

print "1..32\n";

my $bag_n = Set::Bag->new;
my $bag_a = Set::Bag->new(apples => 3, oranges => 4);

print "not " unless $bag_n eq "()";
print "ok 1\n";

print "not " unless $bag_a eq "(apples => 3, oranges => 4)";
print "ok 2\n";

print "not " unless join(":", $bag_a->grab) eq "apples:3:oranges:4";
print "ok 3\n";

print "not " unless join(":", $bag_a->grab('bananas','oranges','plums')) eq
                    "0:4:0";
print "ok 4\n";

my $bag_b = Set::Bag->new(mangos => 3);

$bag_b->insert(apples => 1);
print "not " unless $bag_b eq "(apples => 1, mangos => 3)";
print "ok 5\n";

$bag_b->insert(coconuts => 0);
print "not " unless $bag_b eq "(apples => 1, mangos => 3)";
print "ok 6\n";

$bag_b->remove(mangos => 1);
print "not " unless $bag_b eq "(apples => 1, mangos => 2)";
print "ok 7\n";

eval { $bag_b->remove(mangos => 10) };
print "not "
    unless "$bag_b:$@" eq
           "(apples => 1, mangos => 2):Set::Bag::remove: mangos 2 < 10\n";
print "ok 8\n";

eval { $bag_b->remove(cherries => 1) };
print "not "
     unless "$bag_b:$@" eq
            "(apples => 1, mangos => 2):Set::Bag::remove: cherries 0 < 1\n";
print "ok 9\n";

eval { $bag_b->remove(cherries => 0) };
print "not " unless "$bag_b:$@" eq "(apples => 1, mangos => 2):";
print "ok 10\n";

my $bag_c = $bag_a->sum($bag_b);
print "not " unless $bag_c eq "(apples => 4, mangos => 2, oranges => 4)";
print "ok 11\n";

my $bag_d = $bag_a->union($bag_b);
print "not " unless $bag_d eq "(apples => 3, mangos => 2, oranges => 4)";
print "ok 12\n";

my $bag_e = $bag_a->intersection($bag_b);
print "not " unless $bag_e eq "(apples => 1)";
print "ok 13\n";

my $bag_f = $bag_a->complement;
print "not " unless $bag_f eq "(apples => 1, mangos => 3)";
print "ok 14\n";

print "not " unless $bag_f ne "(apples => 2, mangos => 1)";
print "ok 15\n";

$bag_c = $bag_b->copy;
$bag_c->insert(oranges => 1);
print "not " unless $bag_b eq "(apples => 1, mangos => 2)";
print "ok 16\n";

print "not "
    unless $bag_a + $bag_b eq
           "(apples => 4, mangos => 2, oranges => 4)";
print "ok 17\n";

print "not "
    unless (($bag_c = $bag_a->copy) += $bag_b) eq
	   "(apples => 4, mangos => 2, oranges => 4)";
print "ok 18\n";

my $bag_g = Set::Bag->new(apples => 1, oranges => 1);

print "not "
    unless $bag_a - $bag_g eq
           "(apples => 2, oranges => 3)";
print "ok 19\n";

print "not "
    unless (($bag_c = $bag_a->copy) -= $bag_g) eq
           "(apples => 2, oranges => 3)";
print "ok 20\n";

print "not "
	unless ($bag_a | $bag_b) eq
               "(apples => 3, mangos => 2, oranges => 4)";
print "ok 21\n";

print "not " unless (($bag_c = $bag_a->copy) |= $bag_b) eq
	"(apples => 3, mangos => 2, oranges => 4)";
print "ok 22\n";

print "not "
	unless ($bag_a & $bag_b) eq
               "(apples => 1)";
print "ok 23\n";

print "not " unless (($bag_c = $bag_a->copy) &= $bag_b) eq
	"(apples => 1)";
print "ok 24\n";

print "not " unless -$bag_a eq "(apples => 1, mangos => 3)";
print "ok 25\n";

my $over_remove;
eval { $over_remove = $bag_d->over_remove };
print "not " unless $over_remove == 0;
print "ok 26\n";

eval { $bag_d->over_remove(4,5,6) };
print "not " unless $@ eq
                    "Set::Bag::over_remove: too many arguments (3), want 0 or 1\n";
print "ok 27\n";

$over_remove = $bag_d->over_remove(1);
print "not " unless $over_remove == 1;
print "ok 28\n";

eval { $bag_d->remove(mangos => 5) };
print "not " unless "$bag_d:$@" eq
                    "(apples => 3, oranges => 4):";
print "ok 29\n";

eval { $bag_d->remove(cherries => 1) };
print "not " unless "$bag_d:$@" eq
                    "(apples => 3, oranges => 4):";
print "ok 30\n";

$bag_d->over_remove(0);

eval { $bag_e->insert(cherries => -1) };
print "not "
    unless "$bag_e:$@" eq
           "(apples => 1):Set::Bag::insert: cherries -1 negative\n";
print "ok 31\n";

eval { $bag_e->remove(cherries => -1) };
print "not "
    unless "$bag_e:$@" eq
           "(apples => 1):Set::Bag::remove: cherries -1 negative\n";
print "ok 32\n";

# eof
