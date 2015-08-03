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

my $lenguaje;
#Lista con los colores de restos del parseo del pdf a html
my @unneddedColors = ("#D7D7D7", "#004000", "#9FB99F", "#A0B7A0",
                      "#9CB49E", "#99B499", "#9B9BBF", "#B7C9B7",
                      "#9DADA3", "#9CBD9C", "#9EB0A0", "#000058",
                      "#95B395", "#A1B4A1", "#9DB79D", "#9AAF9A",
                      "#00008C", "#A2B3A2", "#A6B9A6", "#9494C3",
                      "#9BB39B", "#9E9ECC", "#000075", "#9FA9A8",
                      "#000034", "#A1B2AB", "#A2BBA2", "#8F8FB4",
                      "#809B80", "#B1B1DA", "#9FB6A1", "#A8A8DC",
                      "#005600", "#A7BAA7", "#8C8CBA", "#9EABA4",
                      "#000080", "#000059", "#A4A4CA", "#9191D6",
                      "#0000BD", "#9FAE9F", "#98BA98", "#004500",
                      "#9595D0", "#032C03", "#96B596", "#9F9FCB",
                      "#AAB5AA", "#004400", "#9898CD", "#9AB89B",
                      "#9CB89C", "#9FB69F", "#9B9BC5", "#A1B7A1",
                      "#9898D4", "#005400", "#A0BBA0", "#8686A3",
                      "#002900", "#A2B3A7", "#A8A8D3", "#A8A8D3",
                      "#9EB99E", "#B8C9B8", "#9393DF"
                     );

if (! defined $ARGV[0]){die "Ejemplo de uso:\n./paragraph.pl html/ (esp|frc)\n";}
main($ARGV[0]);#Calling main procedure

sub main{
  my ($directory, $lang) = @_;
  my @files = ();

  $lenguaje = $lang;
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

  #Formatear lo mas correctamente posible el HTML
  @htmlContentArr = remove_paragraph(\@htmlContentArr);
  @htmlContentArr = insert_paragraph(\@htmlContentArr);
  @htmlContentArr = remove_empty_paragraphs(\@htmlContentArr);
  @htmlContentArr = add_missing_parenthesis(\@htmlContentArr);
  @htmlContentArr = replace_paragraphs_for_div(\@htmlContentArr);
  @htmlContentArr = divide_speechs(\@htmlContentArr);
  @htmlContentArr = remove_unnedeed_parts(\@htmlContentArr);
  @htmlContentArr = remove_extra_information(\@htmlContentArr);
  @htmlContentArr = remove_extra_chars(\@htmlContentArr);
  @htmlContentArr = remove_empty_tags(\@htmlContentArr);
  @htmlContentArr = reparar_flechas(\@htmlContentArr);
  @htmlContentArr = remover_saltos_innecesarios(\@htmlContentArr);
  @htmlContentArr = reparar_parentesis(\@htmlContentArr);
  @htmlContentArr = alinear_parentesis(\@htmlContentArr);
  @htmlContentArr = alinear_diamantes(\@htmlContentArr);

  #Crear un Archivo con el HTML formateado
  my $nuevo_html = join("/", ("salida", $htmlFileName));
  my $texto = join("\n", @htmlContentArr); 
  open(OUT_HTML, ">", $nuevo_html);
  print OUT_HTML $texto;
  close(OUT_HTML);

  #Decodificar los HTML a UTF8
  map { $_ = decode_entities($_) } @htmlContentArr;

  #Buscamos todas las expresiones regulares en el texto, las devolvemos como un arreglo
  #y usando ese arreglo returnamos un arreglo con una tabla html, la unimos y alamacenamos
  my $entrada_textual = join " ", &crear_tabla("Entrada Textual", &reconocer_entrada_textual($texto));
  my $pronunciacion   = join " ", &crear_tabla("Pronunciacion", &reconocer_pronunciacion($texto));
  my $observacion     = join " ", &crear_tabla("Observacion",  &reconocer_observacion($texto));
  my $etiqueta        = join " ", &crear_tabla("Etiqueta Morfologica", &reconocer_etiqueta_morfologica($texto));
  my $subcontexto     = join " ", &crear_tabla("Subcontexto", &reconocer_sub_contexto($texto));
  my $ejemplo_esp     = join " ", &crear_tabla("Ejemplo Espaniol", &reconocer_ejemplo_esp($texto));
  my $ejemplo_fra     = join " ", &crear_tabla("Ejemplo Frances", &reconocer_ejemplo_fra($texto));
  my $palabra_comp    = join " ", &crear_tabla("Palabras compuestas", &reconocer_palabra_compuesta($texto));

  my @contexto_arr = &reconocer_contexto($texto);
  my $contexto = join " ", &crear_tabla("Contexto", grep { not ($_ =~ /\+/) } @contexto_arr);
  my $patron_g = join " ", &crear_tabla("Patron Gramatical", grep { $_ =~ /\+/ } @contexto_arr);

  #Preparamos un HTML para la salida con las tablas de los elementos encontrados en el texto
  # y lo imprimimos
  my $html_head = "<html><head><title>Salida</title><style>table, th, td {border: 1px solid black;text-align: left;}</style></head><body>";
  my $html_tail = "</body></html>";
  my @bodyA = ($entrada_textual, $pronunciacion, $observacion, $contexto, $patron_g, $etiqueta, $subcontexto, $palabra_comp, $ejemplo_esp, $ejemplo_fra);
  my $body = join "<br><br>", @bodyA;
  my $salida = join " ", ($html_head, $body, $html_tail);
  my $tabla_salida = join "/", ("tablas", $htmlFileName);
  open(OUT_TABLES, ">", $tabla_salida);
  print OUT_TABLES $salida;
  close(OUT_TABLES);

  print "Los archivos han sido creados en salida/$htmlFileName y tablas/$htmlFileName\n";
}

#Este precedimiento remueve parrafos inncesarios en el html de entrada
sub remove_paragraph{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};

  my @linesToDelete = ();

  #Agrego las finlas con los parrafos innecesarios
  for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
    for (my $j=0; $j<= $#unneddedColors; $j++) {
      if (index($htmlContentArr_ref[$i], $unneddedColors[$j]) != -1) {
        push(@linesToDelete, $i);
        last;
      }
    }
  }
  #Elimino las lineas innecesarias
  for (my $i=0; $i<= $#linesToDelete; $i++){
    splice @htmlContentArr_ref, ($linesToDelete[$i]-(3*$i)), 3;
  }

  return @htmlContentArr_ref;
}

#Este procedimiento inserta nuevos parrafos donde son necesarios
sub insert_paragraph{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @colorsToAdd = ("#0000FF", "#008000");
  my @linesToConsider = ();

  #Busco las secciones con los colores que se necesitan
  for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
    for (my $j=0; $j<= $#colorsToAdd; $j++) {
      if (index($htmlContentArr_ref[$i], $colorsToAdd[$j]) != -1 ) {
        push(@linesToConsider, $i);
        last;
      } 
    }
  }

  
  #Agrego las etiquetas de los parrafos
  for (my $i=0; $i<= $#linesToConsider; $i++) {
    my $line = $linesToConsider[$i]+(2*$i);
    splice @htmlContentArr_ref, $line, 0, "<p>";
    splice @htmlContentArr_ref, $line, 0, "</p>";
  }

  return @htmlContentArr_ref;
}

#Esta funcion reemueve parrafos vacios
sub remove_empty_paragraphs{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();

  #Busco parrafos vacios
  for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
    if (index($htmlContentArr_ref[$i], "<p>") >= 0 and index($htmlContentArr_ref[$i+1], "</p>") >= 0) {
      push(@linesToConsider, $i);
    }
  }

  #Eliminamos las etiquetas de apertura y cerrado de parrafos vacios
  for (my $i=0; $i<= $#linesToConsider; $i++) {
    my $line = $linesToConsider[$i]-(2*$i);
    splice @htmlContentArr_ref, $line, 2;
  }

  return @htmlContentArr_ref;
}

#Esta funcion agrega un paratensis de apertura en vez de caracters extras
sub add_missing_parenthesis{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();

  #Buscamos lugares donde se necesite un parentesis de apertura
  for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
    if (index($htmlContentArr_ref[$i], "#008000") >= 0 and index($htmlContentArr_ref[$i+1], ")") >= 0 and index($htmlContentArr_ref[$i+1], "(") < 0 and index($htmlContentArr_ref[$i+1], "AM)") <0) {
      push(@linesToConsider, $i+1);
      $i+=2;
    }
  }

  #Agregamos el parantesis y le hacemos un trim a la palabras antes de agregarle el parentesis de apertura
  for (my $i=0; $i<= $#linesToConsider; $i++) {
    $htmlContentArr_ref[$linesToConsider[$i]] = "(" . ltrim($htmlContentArr_ref[$linesToConsider[$i]]);
  }
  return @htmlContentArr_ref
}

#Reemplazamos las etiquetas de <p> por <div> ya que no es valido tener parrafos anidados
sub replace_paragraphs_for_div{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();
  my $divO = "<div>";
  my $divC = "</div>";
  my $parO = "<p>";
  my $parC = "</p>";


  #Reemplazmos buscando en cada linea
  for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
    $htmlContentArr_ref[$i] =~ s/$parO/$divO/g;
    $htmlContentArr_ref[$i] =~ s/$parC/$divC/g;
  }

  return @htmlContentArr_ref;
}

#Corregimos la indentacion de las etiquetas morfologicas agregando las etiquetas que se necesitan
sub divide_speechs{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();

  #Buscamos las lineas que contienen lo que buscamos
  for my $i (0..$#htmlContentArr_ref) {
    push @linesToConsider, $i if ($htmlContentArr_ref[$i] =~ /#800040;/ and not $htmlContentArr_ref[$i] =~ /italic/);
  }

  #Agregamos las etiquetas que se necesitan para que sea un html correcto
  for my $i (0..$#linesToConsider) {
    my $line = $linesToConsider[$i]+(2*$i);
    splice @htmlContentArr_ref, $line, 0, "<div>";
    splice @htmlContentArr_ref, $line, 0, "</div>";
  }

  return @htmlContentArr_ref;
}

#Removemos lineas que estan con etiquetas vacias
sub remove_unnedeed_parts {
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};

  #Buscamos las lineas con las etiquetas vacias y las eliminamos
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

#Removemos las lineas con informacion extra que ya no necesitamos
sub remove_extra_information {
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();

  #Estas son las palabras claves que se encuentran en esas lineas
  my $lexibase = "Lexibase";
  my $dictionary = "Dictionary Plus";
  my $harper = "HarperCollins";
  my $soft = "Softissimo";
  my $paper = "Paperless";
  my $year = "1999";

  #Buscamos las palabras clave en cada linea
  for my $i (0..$#htmlContentArr_ref) {
    my $line = $htmlContentArr_ref[$i];
    push(@linesToConsider, $i) if ($line =~ /($lexibase|$dictionary|$harper|$soft|$paper|$year)/i);
  }

  #Eliminamos esa linea
  for my $i (0..$#linesToConsider) {
    splice @htmlContentArr_ref, $linesToConsider[$i]-$i, 1;
  }

  return @htmlContentArr_ref;
}

#Removemos lineas con caracteres de espacio y un patrin recurrente que causan un mal formateo
sub remove_extra_chars {
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my $unwanted1 = "11 &nbsp;&nbsp;&nbsp;";
  
  #Buscamos y reemplamos con vacio el patron
  for my $i (0..$#htmlContentArr_ref) {
    $htmlContentArr_ref[$i] =~ s/$unwanted1//g;
  }

  return @htmlContentArr_ref;
}

#Removemos laos tags vacios que esten en el arreglo @tags
sub remove_empty_tags {
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();
  my @tags = ("font", "div");

  #Primer lazo es por cada clase de etqieuta vacia a borrar
  for my $j (0..$#tags) {
    my $tag = $tags[$j];
    #Busca la un par de etiquetas vacias de la etiquetas actual y almacena los indices
    for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
      if ($htmlContentArr_ref[$i] =~ /^[\s]*<$tag>[\s]*$/ and $htmlContentArr_ref[$i+1] =~ /^[\s]*<\/$tag>[\s]*$/) {
        push(@linesToConsider, $i);
        $i++;
      }
    }
    #Elimina las etiquetas vacias de la etiqeuta actual
    for (my $i=0; $i<= $#linesToConsider; $i++) {
      my $line = $linesToConsider[$i]-(2*$i);
      splice @htmlContentArr_ref, $line, 2;
    }
    @linesToConsider = ();
  }

  #Remueve los tags que solo contienen espacios entre ellos
  ##Primer lazo para tag de la lista
  for my $j (0..$#tags) {
    my $tag = $tags[$j];
    #Busca los tags con espacio de la etiqueta actual
    for my $i (0..$#htmlContentArr_ref) {
      if ($htmlContentArr_ref[$i] =~ /<$tag.*>/ and $htmlContentArr_ref[$i+1] =~ /^\s+$/ and $htmlContentArr_ref[$i+2] =~ /<\/$tag>/) {
        push(@linesToConsider, $i);
        $i+=2;
      }
    }
    #Eliminamos la etiquetas con espacios entre ellos
    for (my $i=0; $i<= $#linesToConsider; $i++) {
      my $line = $linesToConsider[$i]-(3*$i);
      splice @htmlContentArr_ref, $line, 3;
    }
    @linesToConsider = ();
  }

  #Una vez mas remueve lo que esta en la lista de etiquetas, por nuevas etiquetas vacias
  for my $j (0..$#tags) {
    my $tag = $tags[$j];
    for (my $i=0; $i<= $#htmlContentArr_ref; $i++){
      if ($htmlContentArr_ref[$i] =~ /^[\s]*<$tag>[\s]*$/ and $htmlContentArr_ref[$i+1] =~ /^[\s]*<\/$tag>[\s]*$/) {
        push(@linesToConsider, $i);
        $i++;
      }
    }
    for (my $i=0; $i<= $#linesToConsider; $i++) {
      my $line = $linesToConsider[$i]-(2*$i);
      splice @htmlContentArr_ref, $line, 2;
    }
    @linesToConsider = ();
  }

  #Busca las lineas que solo tienen `&nbsp`
  @linesToConsider = ();
  for my $i (0..$#htmlContentArr_ref) {
    push(@linesToConsider, $i-1) if ($htmlContentArr_ref[$i] =~ /^[\s]*(&nbsp;)+[\s]*$/);
  }
  #Elimina las lineas que se econtraron
  for (my $i=0; $i<= $#linesToConsider; $i++) {
    my $line = $linesToConsider[$i]-(3*$i);
    splice @htmlContentArr_ref, $line, 3;
  }

 return @htmlContentArr_ref;
}

#Arreglamos como se muestran algunas entradas con `->`
sub reparar_flechas{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();

  #Buscamos las entradas con flechas y divs innecesarios
  for my $i (0..$#htmlContentArr_ref){
    if ($htmlContentArr_ref[$i] =~ /<font style="color:#0000FF;">/ and $htmlContentArr_ref[$i+1] =~ /\-&gt;/ and $htmlContentArr_ref[$i+5] =~ /<font style=\"(font\-weight:bold;)?text\-decoration:underline;color:#0000FF;\">/) {
      push @linesToConsider, $i+3;
    }
  }

  #Eliminamos los divs innecesarios
  for (my $i=0; $i<= $#linesToConsider; $i++) {
    my $line = $linesToConsider[$i]-(2*$i);
    splice @htmlContentArr_ref, $line, 2;
  }

  #Ponemos juntos los elementos que estan con flechas
  @linesToConsider = ();
  for my $i (0..$#htmlContentArr_ref) {
    if ($htmlContentArr_ref[$i] =~ /#0000FF/ and $htmlContentArr_ref[$i+1] =~ /\-&gt;/ and $htmlContentArr_ref[$i+9] =~ /\-&gt;/) {
      push @linesToConsider, $i+6;
    }
  }

  #Eliminamos los divs que no dejan que las entradas esten con flechas
  for (my $i=0; $i<= $#linesToConsider; $i++) {
    my $line = $linesToConsider[$i]-(2*$i);
    splice @htmlContentArr_ref, $line, 2;
  }

  return @htmlContentArr_ref;
}

#Removemos los saltos entre lineas innecesarios
sub remover_saltos_innecesarios{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();

  #saltos innecesarios para los bloques con color #800040
  for my $i (0..$#htmlContentArr_ref){
    if ($htmlContentArr_ref[$i] =~ /<font style=\"font\-style:italic;color:#800040;\"/ and $htmlContentArr_ref[$i+5] =~ /<font.+/) {
      push @linesToConsider, $i+3;
    }
  }

  #Eliminamos los saltos innecesarios para #800040
  for (my $i=0; $i<= $#linesToConsider; $i++) {
    my $line = $linesToConsider[$i]-(2*$i);
    splice @htmlContentArr_ref, $line, 2;
  }

  #saltos innecesarios entre bloques de similar tag de font
  @linesToConsider = ();
  for my $i (0..$#htmlContentArr_ref){
    if ($htmlContentArr_ref[$i] =~ /<font style=\"color:#808080;\">/ ) {
      my $tag_previo = trim($htmlContentArr_ref[$i-3]);
      my $tag_posterior = trim($htmlContentArr_ref[$i+5]);
      if ($tag_previo eq $tag_posterior) {
        push @linesToConsider, $i+3;
      }
    }
  }

  #Eliminamos esos saltos innecesarios
  for (my $i=0; $i<= $#linesToConsider; $i++) {
    my $line = $linesToConsider[$i]-(2*$i);
    splice @htmlContentArr_ref, $line, 2;
  }

  return @htmlContentArr_ref;
}

#Buscamos las lineas que tienen un parentesis sin cerrar y buscamos hasta encontralos
sub reparar_parentesis{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();

  #Almacenamos todas las lineaas que contienen divs innecesarios
  for my $i (0..$#htmlContentArr_ref) {
    if (index($htmlContentArr_ref[$i], "(") !=-1 and index($htmlContentArr_ref[$i], ")") <0) {
      while (index($htmlContentArr_ref[$i], ")") <0) {
        push(@linesToConsider, $i) if ($htmlContentArr_ref[$i] =~ /div/);
        $i++;
      }
    }
  }

  #Eliminamos las lineas marcadas
  for (my $i=0; $i<= $#linesToConsider; $i++) {
    my $line = $linesToConsider[$i]-$i;
    splice @htmlContentArr_ref, $line, 1;
  }

  #Eliminamos lineas con mas de un parentesis de apertura `(`
  for my $i (0..$#htmlContentArr_ref) {
    if (index($htmlContentArr_ref[$i], "(") !=-1 and index($htmlContentArr_ref[$i], ")") <0) {
      while (index($htmlContentArr_ref[$i], ")") <0) { $i++; }
      if ($htmlContentArr_ref[$i] =~ /\([\s]*\)/) {
        $htmlContentArr_ref[$i] =~ s/\(//g;
      }
    }
  }

  return @htmlContentArr_ref;
}

#Eliminamos algunos divs entre parentesis
sub alinear_parentesis{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();

  #buscamos lineas con parentesis entre lineas
  for my $i (0..$#htmlContentArr_ref) {
    if ($htmlContentArr_ref[$i] =~ /color:#008000/ and $htmlContentArr_ref[$i+1] =~ /\(/ and $htmlContentArr_ref[$i-5] =~ /(bold|#808080)/ and not $htmlContentArr_ref[$i-5] =~ /(#0000FF|#800040)/) {
      push @linesToConsider, $i-2;
    }
  }

  #Eliminamos esas lineas
  for (my $i=0; $i<= $#linesToConsider; $i++) {
    my $line = $linesToConsider[$i]-(2*$i);
    splice @htmlContentArr_ref, $line, 2;
  }

  return @htmlContentArr_ref;
}

#Alineamos los diamentes que sirven para numeracion
sub alinear_diamantes{
  my ($htmlContentArr) = @_;
  my @htmlContentArr_ref   =  @{$htmlContentArr};
  my @linesToConsider = ();
  my $divA = "<div>";
  my $divC = "</div>";
  my $fontA = "<font>";
  my $fontC = "</font>";

  #Buscamos algunso diams perdidos
  for my $i (0..$#htmlContentArr_ref) {
    if ($htmlContentArr_ref[$i] =~ /&diams;/) {
      if ($htmlContentArr_ref[$i-2] =~ /$divA/ and $htmlContentArr_ref[$i-1] =~ /$fontA/ and $htmlContentArr_ref[$i+1] =~ /$fontC/ and $htmlContentArr_ref[$i+2] =~ /$divC/) {
        push @linesToConsider, $i-3;
      }
    }
  }

  #Eliiminamos todos esos diams perdidos
  for (my $i=0; $i<= $#linesToConsider; $i++) {
    my $line = $linesToConsider[$i]-(5*$i);
    my @a = splice @htmlContentArr_ref, $line, 5;
  }

  #insertamos los nuevos diams donde se necesitan
  for my $i (0..$#linesToConsider) {
    splice @htmlContentArr_ref, $linesToConsider[$i]+2+$i, 0, "&diams;" if $linesToConsider[$i]+2+$i <= $#htmlContentArr_ref;
  }

  #Insertamos los diams que no esten donde deben, en la posicion correcta
  @linesToConsider = ();
  for my $i (0..$#htmlContentArr_ref) {
    if ($htmlContentArr_ref[$i] =~ /&diams;/ and not $htmlContentArr_ref[$i-1] =~ /<div>/) {
      my $c = $i;
      splice @htmlContentArr_ref, $i, 1;
      while (not $htmlContentArr_ref[$i] =~ /<div>/) {$i--;};
      splice @htmlContentArr_ref, $i+1, 0, "&diams;";
      $i = $c+1;
    }
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
  my @matches = ($texto =~ /<font style=\"font\-weight:bold;color:#0000FF;\">([^<]+)/ );
  map { $_ = trim($_) } @matches;
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
  my @matches = ($texto =~ /<font style=\"font-weight:bold;color:#800040;\">([^<]+)/g );
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
  @matches;
}

sub reconocer_ejemplo_fra{
  #=pod
  #<font style="color:#0000FF;">
  #la casa de Isabel/de mis padres/de los Alvarez 
  #</font>
  #=cut

  my ($texto) = @_;
  my @matches = ( $texto =~/<font>([^<]+)<\/font>/g );
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
  @matches;
}

sub reconocer_palabra_compuesta{
##=pod
##</div>
##<div>
##  <font style="font-weight:bold;color:#0000FF;">
## mano dura 
##</font>
##=cut

  my ($texto) = @_;
  my @matches = ($texto =~ /<\/div>[\n ]+<div>[\n ]+<font style=\"font-weight:bold;color:#0000FF;\">([^<]+)/g);
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
