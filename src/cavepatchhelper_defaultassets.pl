use strict;
use warnings;

use JSON::XS;
use Scalar::Util qw(reftype);

my $jsonPosDecNum_pattern = qr{^\d+$}a;
my $jsonStr_pattern = qr{^([^"]|\\(["\\/bfnrt]|u[0-9a-fA-F]{4}))*$};

# todo clean this subroutine up
sub testStringForValidJSONStringOrPositiveDecimalNumber {
  my ($str, $type, $path, $layerNum) = @_;
  $layerNum //= '?';
  $path //= "#/$str";
  
  my %typePatterns = (
     ARRAY => $jsonPosDecNum_pattern,
     HASH  => $jsonStr_pattern
  );
  
  if (not exists $typePatterns{$type}) {
    warn qq([warning] unrecognised type "$type" at string "$str" in path "$path"(layer $layerNum).\n);
    return
  }
  
  if (exists $typePatterns{$type}) {
    if ($str =~ /$typePatterns{$type}/) {
      return 1;
    }
    warn qq([warning] index/key "$str" does not match the pattern* of type "$type" found in path "$path"(layer $layerNum). * regex: /$typePatterns{$type}/.\n);
    return
  }
  
  die qq(How did you get here?);
}


sub testPathExistence {
  my ($source_Data, $path) = @_;
  
  unless ($path =~ qr"^(/[^/]++)+$") {
    warn qq([warning] invalid path format "$path"\n);
    return
  }
  
  my $layerNum = 0;
  my $temp_ref = $source_Data;
  
  my %changePath = (
     ARRAY => sub {
       my $i = int $_[0];
       if (0 <= $i && $i < @$temp_ref) {
         $temp_ref = $$temp_ref[$i];
         return 1
       }
       warn qq([warning] index "$i" does not exist at "$path"(layer $layerNum).\n);
       return
     },
     HASH  => sub {
       my $key = $_[0];
       if (exists $$temp_ref{$key}) {
         $temp_ref = $$temp_ref{$key};
         return 1
       }
       warn qq([warning] key "$key" does not exist at "$path"(layer $layerNum).\n);
       return
     }
  );
  
  for ($path =~ m"\G/([^/]*+)"g) {
    my $layerStr = $_;
    my $type = Scalar::Util::reftype $temp_ref;
    return unless defined testStringForValidJSONStringOrPositiveDecimalNumber($layerStr, $type, { layerNum => $layerNum, path => $path });
    return unless defined $changePath{$type}->($layerStr);
    $layerNum++;
  }
  
  #change this
  return $temp_ref
}
use Data::Dumper;


sub generateCavePatchOPs {
  my ($source_Data, $key) = @_;
  my $regionTypePath = "/regionTypes/$key";
  
  my @OPs = ();
  
  # my $val = undef; #$$fuPatchOP{value};
  for my $caveSelectorType ('fgCaveSelector', 'bgCaveSelector') {
    my $caveSelectorPath = "$regionTypePath/$caveSelectorType";
    my $caveSelectorValue = 'empty';
  
    my $val = testPathExistence($source_Data, $caveSelectorPath);
    if (defined $val) {
      
      # print Data::Dumper->Dump([$temp]);
      $caveSelectorValue = $$val[0] if @$val and $$val[$#$val] =~ /^empt(y|ie(r|st))$/;
      # $caveSelectorValue = $val if $val =~ /^empt(y|ie(r|st))$/;
    }
    push @OPs, qq#[{"op":"test","path":"$caveSelectorPath"}, {"op":"replace", "path":"$caveSelectorPath", "value":["$caveSelectorValue"]}]#;
  }
  
  return @OPs;
}

my $filename = 'Mod Source DATA/noCaverns_work/patchhelper/assets/DfAs.terrestrial_worlds.config';
open(my $DfAs_terrestrialworlds_fh, '<:encoding(UTF-8)', $filename)
   or die "Could not open file '$filename' $!";
my $DfAs_terrestrialworlds_txt = join '', (@_ = <$DfAs_terrestrialworlds_fh>);
close $DfAs_terrestrialworlds_fh;

# striping comments and decoding
$DfAs_terrestrialworlds_txt =~ s/\/\/.*?(\r?\n)//g;
my $terrestrial_worlds_CONFIG_Data = JSON::XS::decode_json $DfAs_terrestrialworlds_txt;

my @patches = ();
push @patches, generateCavePatchOPs($terrestrial_worlds_CONFIG_Data, $_) for sort keys %{$$terrestrial_worlds_CONFIG_Data{regionTypes}};

$filename = 'Mod Source DATA/noCaverns_work/patchhelper/output/defaultCavePatch_output.txt';
open(my $output, '>:encoding(UTF-8)', $filename)
   or die "Could not create file '$filename' $!";

print {$output} join ",\n", @patches;
close $output;

print 'done';
