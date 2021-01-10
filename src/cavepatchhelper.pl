use strict;
use warnings;

my $tab = '  '; #two spaces
my $tabx2 = $tab x 2;

sub addOPstr {
  my ($path, $value) = @_;
  return qq#{"op": "add", "path": "$path", "value": $value}#
}
sub testOPstr {
  my ($path) = @_;
  return qq#{"op":"test","path":"$path"}#
}

# sub doCavePatchOutput {
#   my ($fuPatchOP) = @_;
#   my $regionTypePath = $$fuPatchOP{path};
#   
#   my @caveRemovalOPs = (testOPstr($regionTypePath));
#   
#   my $val = $$fuPatchOP{value};
#   for (('fgCaveSelector', 'bgCaveSelector')) {
#     my $caveSelectorPath = "$regionTypePath/$_";
#     if (exists $$val{$_}) {
#       my $temp = $$val{$_};
#       my $caveSelectorValue = '["empty"]';
#       $caveSelectorValue = (($$temp[0] =~ /empt(y|ie(r|st))/ && qq#["$$temp[0]"]#) or '["empty"]');
#       
#       push @caveRemovalOPs, addOPstr($caveSelectorPath, $caveSelectorValue);
#     }
#   }
#   
#   return if @caveRemovalOPs == 1;
#   my $OPs = join ",\n", map {"$tabx2$_"} @caveRemovalOPs;
#   
#   return "$tab\[\n$OPs\n$tab]";
# }
# sub doCavePatchOutput {
#   my ($fuPatchOP) = @_;
#   my $regionTypePath = $$fuPatchOP{path};
#   
#   # my @caveRemovalOPs = testOPstr($regionTypePath);
#   my @caveRemovalOPs = '';
#   
#   my $val = $$fuPatchOP{value};
#   for ('fgCaveSelector', 'bgCaveSelector') {
#     my $caveSelectorPath = "$regionTypePath/$_";
#     my $caveSelectorValue = '["empty"]';
#     if (exists $$val{$_}) {
#       my $temp = $$val{$_};
#       $caveSelectorValue = (($$temp[0] =~ /^empt(y|ie(r|st))$/ && qq#["$$temp[0]"]#) or '["empty"]');
#       # push @caveRemovalOPs, addOPstr($caveSelectorPath, $caveSelectorValue);
#     }
#     push @caveRemovalOPs, qq#[{"op":"test","path":"$caveSelectorPath"}, {"op":"replace", "path":"$caveSelectorPath", "value":$caveSelectorValue}]#;
#   }
#   
#   shift @caveRemovalOPs;
#   
#   # return if @caveRemovalOPs == 1;
#   my $OPs = join ",\n", map {"  $_"} @caveRemovalOPs;
#   # $OPs = "[\n$OPs\n]";
#   $OPs = qq#[{"op":"test","path":"$regionTypePath"}, [\n$OPs\n]]#;
#   return $OPs;
# }
sub generateCavePatchOPs {
  my ($fuPatchOP) = @_;
  my $regionTypePath = $$fuPatchOP{path};
  
  # my @caveRemovalOPs = testOPstr($regionTypePath);
  my @caveRemovalOPs = '';
  
  my $val = $$fuPatchOP{value};
  for ('fgCaveSelector', 'bgCaveSelector') {
    my $caveSelectorPath = "$regionTypePath/$_";
    my $caveSelectorValue = 'empty';
    if (exists $$val{$_}) {
      my $temp = $$val{$_};
      $caveSelectorValue = (($$temp[0] =~ /^empt(y|ie(r|st))$/ && qq#$$temp[0]#) or 'empty');
      # push @caveRemovalOPs, addOPstr($caveSelectorPath, $caveSelectorValue);
    }
    push @caveRemovalOPs, qq#[{"op":"test","path":"$caveSelectorPath"}, {"op":"replace", "path":"$caveSelectorPath", "value":["$caveSelectorValue"]}]#;
  }
  
  shift @caveRemovalOPs;
  
  # return if @caveRemovalOPs == 1;
  my $OPs = join ",\n", map {"  $_"} @caveRemovalOPs;
  # $OPs = "[\n$OPs\n]";
  # $OPs = qq# [\n$OPs\n]#;
  return $OPs;
}



my $filename = 'Mod Source DATA/noCaverns_source/assets/terrestrial_worlds.frackinpatch.config.patch';
open(my $FUregionTypesJSONpatchDataFile, '<:encoding(UTF-8)', $filename)
   or die "Could not open file '$filename' $!";

my $FUregionTypesJSONpatchText = join '', (@_ = <$FUregionTypesJSONpatchDataFile>);
close $FUregionTypesJSONpatchDataFile;

use JSON::XS;
my $FUpatchData = decode_json $FUregionTypesJSONpatchText;

# use Data::TreeDumper;
# print Data::TreeDumper::DumpTree($FUpatchData, "dump", NO_PACKAGE_SETUP => 1);

my @patches = ();
push @patches, generateCavePatchOPs($_) for (@$FUpatchData);

$filename = 'Mod Source DATA/noCaverns_source/output/frackinCavePatch_output.txt';
open(my $output, '>:encoding(UTF-8)', $filename)
   or die "Could not create file '$filename' $!";

print {$output} join ",\n", @patches;
close $output;

print 'done';
