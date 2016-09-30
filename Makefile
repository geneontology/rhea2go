OBO=        http://purl.obolibrary.org/obo

all: mf-merged.owl

#########################################
#
# Downloads
#
tsv: rhea-tsv.tar.gz
	tar -zxvf $<


rhea-tsv.tar.gz:
	wget ftp://ftp.ebi.ac.uk/pub/databases/rhea/tsv/rhea-tsv.tar.gz


rhea-biopax_lite.owl: rhea-biopax_lite.owl.gz
	gzip -d $<

rhea-biopax_lite.owl.gz:
	wget ftp://ftp.ebi.ac.uk/pub/databases/rhea/biopax/$@


#########################################
#
# Blazegraph
#

BGJAR = jars/blazegraph.jar

$(BGJAR):
	mkdir -p jars && cd jars && curl -O http://tenet.dl.sourceforge.net/project/bigdata/bigdata/2.1.1/blazegraph.jar
.PRECIOUS: $(BGJAR)

BG = java -XX:+UseG1GC -Xmx12G -cp $(BGJAR) com.bigdata.rdf.store.DataLoader -defaultGraph http://geneontology.org/rdf/ conf/blazegraph.properties
load-blazegraph: $(BGJAR)
	$(BG) rhea-biopax_lite.owl

rmcat:
	rm rdf/catalog-v001.xml

rdf/%-bg-load: rdf/%.rdf
	$(BG) $<

bg-start:
	java -server -Xmx8g -Dbigdata.propertyFile=conf/blazegraph.properties -jar $(BGJAR)

#########################################
#
# QUERIES
#

target/%.tsv: sparql/%.sparql
	curl   http://localhost:9999/blazegraph/sparql --data-urlencode query@$< -H 'Accept: text/tab-separated-values' > $@

# make the obo file from (1) rhea to chebi links and (2) rhea xrefs plus parents and other metadata
rhea.obo: target/rhea.tsv tsv/rhea2xrefs.tsv 
	./util/rhea-tsv2obo.pl $^ > $@

