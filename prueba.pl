#!/usr/bin/perl -w


my $entrada1 = { "id" => 0, "entrada" => "pre", "palabra_compuesta" => "" };
my $entrada2 = { "id" => 1, "entrada" => "post", "palabra_compuesta" => "" };
#print "%entrada1\n";
#print "%entrada2\n";
#my @array = ($entrada1, $entrada2);

#map { print "$$_{id}\n" } @array;

my @array = ();
my $c = 0;
my @temp = (1, 2, 3, 4);
map { push @array, { "id" => $_, "entrada" => "algo", "palabra_compuesta" => "cmp" }; $c++ } @temp;
my @salida = ();
map { push @salida, "$$_{id}\t$$_{entrada}\t$$_{palabra_compuesta}" } @array;
my $texto = join "\n", @salida;
print "$texto\n";

print "++++++++++++++++++++++++++++++++++++++++++\n";
my $s = 2;
my $matching;
($matching) = grep { $$_{id} == 5 } @array;
print "MATCHING: $$matching\b";
print "ID: $$matching{id}\n";
splice @temp, 2, 1;
print "TEMP: @temp\n";
#print "++++++++++++++++++++++++++++++++++++++++++\n";
#my @array2 = ();
#push @array2, %entrada1;
#push @array2, %entrada2;
#@salida = ();
#map { push @salida, "$$_{id}\t$$_{entrada}\t$$_{palabra_compuesta}" } @array2;
#$texto = join "\n", @salida;
#print "$texto\n";
#print "++++++++++++++++++++++++++++++++++++++++++\n";
#my $lenght = scalar(@array) -1;
#print "TAMANO: $lenght\n";
#for my $i (0..$lenght) {
  #print "###################\n";
  #my %mihash = %{ $array[$i] };
  #foreach my $val (keys %mihash) {
    #print "- $val\n";
  #}
  #print "###################\n";
#}

#print "++++++++++++++++++++++++++++++++++++++++++\n";
#my @salida_arr = ();
#my $lenght = scalar(@array) -1;
#for my $i (0..$lenght) {
  #my @registro = ();
  #my %elemento = %{ $array[$i] };
  #foreach (keys %elemento) {
    #push @registro, $elemento{$_};
  #}
  #print "REGISTRO: @registro\n";
  #push @salida_arr, join("\t", @registro);
#}

#my $texto = join "\n", @salida_arr;
#print "$texto\n";
#print "n= $#array2\n";
