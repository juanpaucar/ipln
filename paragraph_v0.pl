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

my @unneddedColors = ("#D7D7D7", "#004000","#9FB99F", "#A0B7A0", "#9CB49E", "#99B499", "#9B9BBF", "#B7C9B7");

if (! defined $ARGV[0]){die "Ejemplo de uso:\n./paragraph.pl html/do.html\n";}
main($ARGV[0]);#Calling main procedure


sub main{
  my ($htmlFileName) = @_;

  #Abrir el archivo y almacenarlo en un arreglo
  my $htmlContent = openFile($htmlFileName);
  my @htmlContentArr = split('\n', $htmlContent); 

  #Formatear lo mas ocrrectamente posible el HTML
  @htmlContentArr = remove_paragraph(\@htmlContentArr);
  @htmlContentArr = insert_paragraph(\@htmlContentArr);
  @htmlContentArr = remove_empty_paragraphs(\@htmlContentArr);
  @htmlContentArr = add_missing_parenthesis(\@htmlContentArr);
  @htmlContentArr = replace_paragraphs_for_div(\@htmlContentArr);
  @htmlContentArr = nest_divs(\@htmlContentArr);

  #Decodificar los HTML a UTF8
  map { $_ = decode_entities($_) } @htmlContentArr;

  #Crear un Archivo con el HTML formateado
  my $texto = join(" ", @htmlContentArr); 
  open(OUT_HTML, ">", "salida.html");
  print OUT_HTML $texto;
  close(OUT_HTML);

  #Buscamos todas las expresiones regulares en el texto, las devolvemos como un arreglo
  #y usando ese arreglo returnamos un arreglo con una tabla html, la unimos y alamacenamos
  my $entrada_textual = join " ", &crear_tabla("Entrada Textual", &reconocer_entrada_textual($texto));
  my $pronunciacion   = join " ", &crear_tabla("Pronunciacion", &reconocer_pronunciacion($texto));
  my $observacion     = join " ", &crear_tabla("Observacion",  &reconocer_observacion($texto));
  my $contexto        = join " ", &crear_tabla("Contexto", &reconocer_contexto($texto));
  my $etiqueta        = join " ", &crear_tabla("Etiqueta Morfologica", &reconocer_etiqueta_morfologica($texto));
  my $subcontexto     = join " ", &crear_tabla("Subcontexto", &reconocer_sub_contexto($texto));
  my $ejemplo         = join " ", &crear_tabla("Ejemplo", &reconocer_ejemplo_esp($texto));


  #Preparamos un HTML para la salida con las tablas de los elementos encontrados en el texto
  # y lo imprimimos
  my $html_head = "<html><head><title>Salida</title><style>table, th, td {border: 1px solid black;text-align: left;}</style></head><body>";
  my $html_tail = "</body></html>";
  my @bodyA = ($entrada_textual, $pronunciacion, $observacion, $contexto, $etiqueta, $subcontexto, $ejemplo);
  my $body = join "<br><br>", @bodyA;
  my $salida = join " ", ($html_head, $body, $html_tail);
  open(OUT_TABLES, ">", "tablas.html");
  print OUT_TABLES $salida;
  close(OUT_TABLES);

  print "Los archivos `salida.html` y `tablas.html` hasn sido generados en el directorio actual\n";
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
      if (index($htmlContentArr_ref[$i], $colorsToAdd[$j]) != -1 ) {
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

sub reconocer_entrada_textual{
  #=pod
  #Identificando una entrada:
  #<font style="font-weight:bold;color:#0000FF;">
  #  de 
  #</font>
  #=cut

  my ($texto) = @_;
  my @matches = ($texto =~ /<font  style=\"font\-weight:bold;color:#0000FF;\">[\s]+([\/a-zA-Zàáäâéèëêíìïîóòöôúùüû]+)[\s]+<\/font>/ );

  #print "entrada\n";
  #map { print "- $_\n" } @matches;
  @matches;
}

sub reconocer_pronunciacion{
  #=pod
  #Identificando la pronunciación:
  #<font style=\"color:#CD4970">
  #  /de/
  #</font>
  #=cut

  my ($texto) = @_;
  my @matches = ($texto =~ /<font style=\"color:#CD4970;\">[\s]+([\/a-zA-Zàáäâéèëêíìïîóòöôúùüû]+)[\s]+<\/font>/ );

  #print "pronunciacion\n";
  #map { print "- $_\n" } @matches;
  @matches;
}

sub reconocer_etiqueta_morfologica{
  #=pod
  #Identificando la etiqueta morfologica:
  #<font style=\"font-weight:bold;color:#800040">
  #  prep
  #</font>
  #=cut

  my ($texto) = @_;
  my @matches = ($texto =~ /<font style=\"font-weight:bold;color:#800040;\">[\s]+([a-zA-Zàáäâéèëêíìïîóòöôúùüû]+)[\s]+<\/font>/ );

  #print "Etiqueta morfologica\n";
  #map { print "- $_\n" } @matches;
  @matches;
}

sub reconocer_observacion{
  #=pod
  #Identificando la observacion:
  #<font style="color:#CD4970;">
  #/de/
  #</font>
  #</div>
  #<div style="margin-left:30px;">
  #<div>
  #<font style="font-weight:bold;">
  #de + el = 
  #</font>
  #=cut

  my ($texto) = @_;
  my @matches = ( $texto =~ /<font style=\"font-weight:bold;\">[\s]+([a-zA-Zàáäâéèëêíìïîóòöôúùüû\+\=\s]+)[\s]+<\/font>/ );

  #print "Observacion\n";
  #map { print "- $_\n" } @matches;
  @matches;
}

sub reconocer_contexto{
  #=pod
  #Identificando el contexto:
    #<(\font style=\"font style="color:#008000)>
      #(gen, complemento de n)
    #</font>
  #=cut
  #=pod 
  #<font style=\"font style="color:#008000;\">[\s]+([\(a-zA-Zàáäâéèëêíìïîóòöôúùüû\)]+)[\s]+<\/font>[^\)]/ 
  #=cut

  my ($texto) = @_;
  my @matches = ( $texto =~ /\(([^\)]+)/ );

  #print "Contexto\n";
  #map { print "- $_\n" } @matches;
  @matches;
}




sub reconocer_ejemplo_esp{
  #=pod
    #<font style="color:#0000FF;">
      #la casa de Isabel/de mis padres/de los Alvarez 
    #</font>
  #=cut

  my ($texto) = @_;
  my @matches = ( $texto =~/<font style=\"color:#0000FF;\">([a-zA-Zàáäâéèëêíìïîóòöôúùüû\/\s]+)[\s]+<\/font>/ );

  #print "EjemploEspaniol\n";
  #map { print "- $_\n" } @matches;
  @matches;
}

#=pod
#my $ejemplo_fra = $1 if ($ejemplo =~/<font>([a-zA-Zàáäâéèëêíìïîóòöôúùüû\/\s]+)[\s]+<\/font>/);
#{
#print "EjemploFrances= $ejemplo_fra\n";
#}

#=cut

sub  reconocer_sub_contexto{
  #=pod
  #Identificando el Subcontexto:
  #<font style="color:#008000;">

  #</font>
  #=cut
  my ($texto) = @_;
  my @matches = ( $texto =~ /<font style="color:#008000;">[\s]+([a-zA-Zàáäâéèëêíìïîóòöôúùüû]+\+[a-zA-Zàáäâéèëêíìïîóòöôúùüû]+)[\s]+<\/font>/ );

  #print "SubContexto=\n";
  #map { print "- $_\n" } @matches;
  @matches;
}

sub crear_tabla{
  my ($titulo, @elementos) = @_;
  my @html_table = ();
  push(@html_table, "<table>");
  push(@html_table, "<tr>");
  push(@html_table, "<th>");
  push(@html_table, $titulo);
  push(@html_table, "</th>");
  push(@html_table, "</tr>");

  map { push(@html_table, "<tr><td>$_</td></tr>") } @elementos;

  push(@html_table, "</table>");
  @html_table;
}
