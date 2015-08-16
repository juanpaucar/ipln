#!/usr/bin/perl -w

my @array = (1);

if ($#array >= 0) {
  print "TAM: $#array";
}

my @a1 = (1,2, 3);
my @a2 = (4, 5, 6);

my @a3 = (@a1, @a2);
print "\nA3: @a3\n";
my $v = shift @a3;

print "\nv: $v\n";
