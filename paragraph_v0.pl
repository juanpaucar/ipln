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

my @unneddedColors = ("#D7D7D7", "#004000", "#9FB99F", "#A0B7A0",
                      "#9CB49E", "#99B499", "#9B9BBF", "#B7C9B7",
                      "#9DADA3", "#9CBD9C", "#9EB0A0", "#000058",
                      "#95B395", "#A1B4A1", "#9DB79D", "#9AAF9A",
                      "#00008C", "#A2B3A2", "#A6B9A6", "#9494C3",
                      "#9BB39B", "#9E9ECC", "#000075", "#9FA9A8",
                      "#000034", "#A1B2AB", "#A2BBA2", "#8F8FB4",
                      "#809B80", "#B1B1DA", "#9FB6A1", "#A8A8DC",
                      "#005600", "#A7BAA7", "#8C8CBA", "#9EABA4",
                      "#000080", "#000059"
                     );

if (! defined $ARGV[0]){die "Ejemplo de uso:\n./paragraph.pl html/do.html\n";}
main($ARGV[0]);#Calling main procedure

sub main{
  my ($directory) = @_;
  my @files = ();

  #Buscamos cada archivo en el directorio que recibimos de argumento
  opendir (DIR, $directory) or die $!;
  while (my $file = readdir(DIR)) {
    push @files, $file if (not $file =~ /DS_Store/);
  }
  closedir(DIR);

  #Nos deshacemos de `.` y `..`
  splice @files, 0, 2;

  #Eliminamos las caprteas de ejecuciones anteriores
  #si es la primera vez que ejecutamos simplemente nos dara un error
  #pero seguira con la ejecucion del programa
  system("rm", ("-rf", "salida"));
  system("mkdir", "salida");
  system("rm", ("-rf", "tablas"));
  system("mkdir", "tablas");

  #Procesamos cada archivo en la carpeta
  map { process_html($directory, $_) } @files;
}

sub process_html{
  my ($directory, $htmlFileName) = @_;

  #Abrir el archivo y almacenarlo en un arreglo
  my $total_path = join("/", ($directory, $htmlFileName));
  my $htmlContent = openFile($total_path);
  my @htmlContentArr = split('\n', $htmlContent); 

  #Formatear lo mas ocrrectamente posible el HTML
  @htmlContentArr = remove_paragraph(\@htmlContentArr);
  @htmlContentArr = insert_paragraph(\@htmlContentArr);
  @htmlContentArr = remove_empty_paragraphs(\@htmlContentArr);
  @htmlContentArr = add_missing_parenthesis(\@htmlContentArr);
  @htmlContentArr = replace_paragraphs_for_div(\@htmlContentArr);
  @htmlContentArr = divide_speechs(\@htmlContentArr);
  @htmlContentArr = remove_unnedeed_parts(\@htmlContentArr);
  @htmlContentArr = remove_extra_information(\@htmlContentArr);

  #Decodificar los HTML a UTF8
  map { $_ = decode_entities($_) } @htmlContentArr;

  #Crear un Archivo con el HTML formateado
  my $nuevo_html = join("/", ("salida", $htmlFileName));
  my $texto = join("\n", @htmlContentArr); 
  open(OUT_HTML, ">", $nuevo_html);
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
  my $tabla_salida = join "/", ("tablas", $htmlFileName);
  open(OUT_TABLES, ">", $tabla_salida);
  print OUT_TABLES $salida;
  close(OUT_TABLES);

  print "Los archivos han sido creados en salida/$htmlFileName y tablas/$htmlFileName\n";
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

#This function removes paragraphs with no content
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

#This function adds an openning paranthesis to some lines that had extra chars instead of `(`
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

#We replace <p> with <div> since is incorrect to have nested paragraphs
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

sub divide_speechs{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();

  for my $i (0..$#htmlContentArr_ref) {
    push @linesToConsider, $i if ($htmlContentArr_ref[$i] =~ /#800040;/ and not $htmlContentArr_ref[$i] =~ /italic/);
  }

  for my $i (0..$#linesToConsider) {
    my $line = $linesToConsider[$i]+(2*$i);
    splice @htmlContentArr_ref, $line, 0, "<div>";
    splice @htmlContentArr_ref, $line, 0, "</div>";
  }

  return @htmlContentArr_ref;
}

sub remove_unnedeed_parts {
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  for my $i (0..$#htmlContentArr_ref) {
    if ($htmlContentArr_ref[$i] =~ /font\-weight:bold;text\-decoration:underline;color:#0000FF;/) {
      if (index($htmlContentArr_ref[$i+5], "<font style=\"font-weight:bold;\">") != -1) {
        splice @htmlContentArr_ref, $i+3, 5;
        last;
      }
    }
  }
  return @htmlContentArr_ref;
}

sub remove_extra_information {
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();
  my $lexibase = "Lexibase";
  my $dictionary = "Dictionary Plus";
  my $harper = "HarperCollins";
  my $soft = "Softissimo";

  for my $i (0..$#htmlContentArr_ref) {
    my $line = $htmlContentArr_ref[$i];
    push(@linesToConsider, $i) if ($line =~ /($lexibase|$dictionary|$harper|$soft)/i);
  }

  for my $i (0..$#linesToConsider) {
    splice @htmlContentArr_ref, $linesToConsider[$i]-$i, 1;
  }

  return @htmlContentArr_ref;
}

#taken from http://perlmaven.com/trim
sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

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
  my @matches = ($texto =~ /<font style=\"font\-weight:bold;color:#0000FF;\">([^<]+)/g );

  map { $_ = trim($_) } @matches;
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
  my @matches = ($texto =~ /<font style=\"color:#CD4970;\">[\s]+([\/a-zA-Zàáäâéèëêíìïîóòöôúùüû]+)[\s]+<\/font>/g );

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
  my @matches = ($texto =~ /<font style=\"font-weight:bold;color:#800040;\">[\s]+([a-zA-Zàáäâéèëêíìïîóòöôúùüû]+)[\s]+<\/font>/g );

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
  my @matches = ( $texto =~ /<font style=\"font-weight:bold;\">[\s]+([a-zA-Zàáäâéèëêíìïîóòöôúùüû\+\=\s]+)[\s]+<\/font>/g );

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
  my @matches = ( $texto =~ /\<div>[\n ]+<font style=\"color:#008000;\">([^<]+)/g );

  map { $_ = trim ($_) } @matches;
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
  my @matches = ( $texto =~/<font style=\"color:#0000FF;\">([a-zA-Zàáäâéèëêíìïîóòöôúùüû\/\s]+)[\s]+<\/font>/g );

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
  my @matches = ( $texto =~ /<font style="color:#008000;">[\s]+([a-zA-Zàáäâéèëêíìïîóòöôúùüû]+\+[a-zA-Zàáäâéèëêíìïîóòöôúùüû]+)[\s]+<\/font>/g );

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
