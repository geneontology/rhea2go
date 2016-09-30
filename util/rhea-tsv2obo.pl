#!/usr/bin/perl

use strict;

print "ontology: rhea\n";
print "subsetdef: BI \"BI\"\n";
print "subsetdef: LR \"LR\"\n";
print "subsetdef: RL \"RL\"\n";
print "subsetdef: UN \"UN\"\n";
print "\n";

my %leftmap = ();
my %rightmap = ();
my %namemap = ();

my $f1 = shift @ARGV;
my $f2 = shift @ARGV;
open(F,$f1) || die $f1;
while(<F>) {
    next if /^\?/;
    chomp;
    my ($uri,$n,$dir,$chebi) = split(/\t/,$_);
    $n =~ s@"(.*)"\^\^.*@$1@;
    $n =~ s@\{@\\\{@g;
    $n =~ s@\}@\\\}@g;
    $uri =~ s@<http://identifiers.org/rhea/(\d+)>@RHEA:$1@;
    $chebi =~ s@<http://purl.obolibrary.org/obo/CHEBI_(\d+)>@CHEBI:$1@;
    if ($dir =~ /left/i) {
        push(@{$leftmap{$uri}}, $chebi);
    }
    else {
        push(@{$rightmap{$uri}}, $chebi);
    }
    $namemap{$uri} = $n;
}
close(F);

my %done = ();
my $last;

open(F,$f2) || die $f2;
while(<F>) {
    chomp;
    next if m@^RHEA_ID@;
    my ($id,$d,$parent,$xacc,$xdb) = split(/\t/,$_);
    if (!$done{$id}) {
        my $rid = "RHEA:$id";
        my $n = $namemap{$rid};
        print "\n";
        print "[Term]\n";
        print "id: $rid\n";
        print "name: $n\n" if $n;
        print "subset: $d\n";
        print "is_a: RHEA:$parent\n";
        foreach my $x (@{$leftmap{$rid}}) {
            print "relationship: left $x\n";
        }
        foreach my $x (@{$rightmap{$rid}}) {
            print "relationship: right $x\n";
        }
        $done{$id} = 1;
    }
    else {
        die "$last != $id" unless $last eq $id || !$last;
    }
    print "xref: $xdb:$xacc\n" unless $xdb eq 'UNIPROT';

    $last = $id;
    
}
close(F);
exit 0;
