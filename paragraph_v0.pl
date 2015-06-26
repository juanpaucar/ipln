#!/usr/bin/perl -w
#Procesamiento de Lenguajes Naturales
#Profesor:Dr. Josafá Pontes
#Número de la dupla:
#Nombres e apellidos:
#Direccion de traducción:


use Encode;
use utf8;
use HTML::Entities;#Convert html encoding into utf8 plain text and vice versa
use warnings;
use strict;
binmode STDOUT, ":utf8";

my @unneddedColors = ("#D7D7D7", "#004000","#9FB99F", "#A0B7A0", "#9CB49E");

if (! defined $ARGV[0]){die "Ejemplo de uso:\n./paragraph.pl English-Spanish/html/do.html\n";}
main($ARGV[0]);#Calling main procedure


sub main{
  my ($htmlFileName) = @_;

  #Opening file and storing it into array
  my $htmlContent = openFile($htmlFileName);
  my @htmlContentArr = split('\n', $htmlContent); 

  @htmlContentArr = remove_paragraph(\@htmlContentArr);
  @htmlContentArr = insert_paragraph(\@htmlContentArr);
  @htmlContentArr = remove_empty_paragraphs(\@htmlContentArr);
  @htmlContentArr = add_missing_parenthesis(\@htmlContentArr);
  @htmlContentArr = replace_paragraphs_for_div(\@htmlContentArr);
  @htmlContentArr = nest_divs(\@htmlContentArr);

  # Printing the modified array
  for (my $i=0; $i<= $#htmlContentArr; $i++){
    my $line = $htmlContentArr[$i];
    print "$line\n";
  }



  # Printing the modified array using three encodings
  for (my $i=0; $i<= $#htmlContentArr; $i++){
    my $line_html_original = $htmlContentArr[$i];
    #print "$i\torig\t$line_html_original\n";
    my $line_utf8 = decode_entities($line_html_original);#Converting html encoding into utf8 plain text
    #print "$i\tutf8\t$line_utf8\n";
    my $line_html_full = encode_entities($line_utf8);#Converting utf8 plain text into html encoding
    #print "$i\tfull\t$line_html_full\n\n";
  }

}

#This procedure removes unwanted paragraphs from the html input array.
#The removal is based on a visual comparison between the html input file and the corresponding pdf file (reference).
sub remove_paragraph{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};

  my @linesToDelete = ();

  #Elimino partes innecesarias
  for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
    for (my $j=0; $j<= $#unneddedColors; $j++) {
      if (index($htmlContentArr_ref[$i], $unneddedColors[$j]) != -1) {
        push(@linesToDelete, $i);
        last;
      }
    }
  }
  for (my $i=0; $i<= $#linesToDelete; $i++){
    splice @htmlContentArr_ref, ($linesToDelete[$i]-(3*$i)), 3;
  }

  return @htmlContentArr_ref;
}

#This procedure inserts new paragraphs into the html input array.
#The insertion is based on a visual comparison between the html input file and the corresponding pdf file (reference).
sub insert_paragraph{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @colorsToAdd = ("#0000FF", "#008000");
  my @linesToConsider = ();

  for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
    for (my $j=0; $j<= $#colorsToAdd; $j++) {
      if (index($htmlContentArr_ref[$i], $colorsToAdd[$j]) != -1) {
        push(@linesToConsider, $i);
        last;
      }
    }
  }

  for (my $i=0; $i<= $#linesToConsider; $i++) {
    my $line = $linesToConsider[$i]+(2*$i);
    splice @htmlContentArr_ref, $line, 0, "<p>";
    splice @htmlContentArr_ref, $line, 0, "</p>";
  }

  return @htmlContentArr_ref;
}

sub remove_empty_paragraphs{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();

  for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
    if (index($htmlContentArr_ref[$i], "<p>") >= 0 and index($htmlContentArr_ref[$i+1], "</p>") >= 0) {
      push(@linesToConsider, $i);
    }
  }

  for (my $i=0; $i<= $#linesToConsider; $i++) {
    my $line = $linesToConsider[$i]-(2*$i);
    splice @htmlContentArr_ref, $line, 2;
  }

  return @htmlContentArr_ref;
}

sub add_missing_parenthesis{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();
  for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
    if (index($htmlContentArr_ref[$i], "#008000") >= 0 and index($htmlContentArr_ref[$i+1], ")") >= 0 and index($htmlContentArr_ref[$i+1], "(") < 0) {
      push(@linesToConsider, $i+1);
      $i+=2;
    }
  }

  for (my $i=0; $i<= $#linesToConsider; $i++) {
    $htmlContentArr_ref[$linesToConsider[$i]] = "(" . ltrim($htmlContentArr_ref[$linesToConsider[$i]]);
  }
  return @htmlContentArr_ref
}

sub replace_paragraphs_for_div{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();
  my $divO = "<div>";
  my $divC = "</div>";
  my $parO = "<p>";
  my $parC = "</p>";

  for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
    $htmlContentArr_ref[$i] =~ s/$parO/$divO/g;
    $htmlContentArr_ref[$i] =~ s/$parC/$divC/g;
  }

  return @htmlContentArr_ref;
}

sub nest_divs{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my $openDiv;

  for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
    if (index($htmlContentArr_ref[$i], "#CD4970") != -1) {
      $openDiv = $i;
      last;
    }
  }

  splice @htmlContentArr_ref, $openDiv + 4, 0, "<div style=\"margin-left:30px;\">";
  splice @htmlContentArr_ref, $#htmlContentArr_ref - 2, 0, "</div>";

  return @htmlContentArr_ref;
}

sub ltrim { my $s = shift; $s =~ s/^\s+//; return $s }; #taken from http://perlmaven.com/trim

sub openFile{
    my ($fileName) = @_;
    local $/;#read full file instead of only one line.
    open(FILE, "<:utf8",$fileName) or die "Can't read file \"$fileName\" [$!]\n";
    my $fileContent = <FILE>;
    close (FILE);
    
    return $fileContent;
}
