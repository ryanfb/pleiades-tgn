SHELL:=/bin/bash

all: pleiades-tgn.csv pleiades-tgn.ttl

full.zip:
	wget http://vocab.getty.edu/dataset/tgn/full.zip

TGNOut_Full.nt: full.zip
	7za x full.zip -aos

labels.nt: TGNOut_Full.nt
	fgrep '<http://www.w3.org/2000/01/rdf-schema#label>' TGNOut_Full.nt > labels.nt

parents.nt: TGNOut_Full.nt
	fgrep '<http://vocab.getty.edu/ontology#parentString>' TGNOut_Full.nt > parents.nt

geometries.nt: TGNOut_Full.nt
	grep '<http://schema.org/latitude\|longitude>' TGNOut_Full.nt > geometries.nt

pleiades-places-latest.csv:
	wget http://atlantides.org/downloads/pleiades/dumps/$@.gz
	gunzip $@.gz

pleiades-names-latest.csv:
	wget http://atlantides.org/downloads/pleiades/dumps/$@.gz
	gunzip $@.gz

pleiades-tgn.csv: pleiades-tgn.rb labels.nt parents.nt geometries.nt pleiades-places-latest.csv pleiades-names-latest.csv
	cat <(echo 'tgn_uri,pleiades_uri,tgn_label,tgn_parentstring') <(./pleiades-tgn.rb labels.nt parents.nt geometries.nt pleiades-places-latest.csv pleiades-names-latest.csv | sort -u) > $@

pleiades-tgn.ttl: pleiades-tgn.csv
	./toPelagiosRDF.py

clean:
	rm -vf pleiades-*-latest.csv *.nt full.zip
