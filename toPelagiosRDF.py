import csv

with open('pleiades-tgn.csv') as f:
  output = open('pleiades-tgn.ttl', 'w')

  output.write('@prefix dcterms: <http://purl.org/dc/terms/> .\n')
  output.write('@prefix foaf: <http://xmlns.com/foaf/0.1/> .\n')
  output.write('@prefix geo: <http://www.w3.org/2003/01/geo/wgs84_pos#> .\n')
  output.write('@prefix lawd: <http://lawd.info/ontology/> .\n')
  output.write('@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n')
  output.write('@prefix skos: <http://www.w3.org/2004/02/skos/core#> .\n')
  output.write('@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n\n')

  reader = csv.reader(f, delimiter=',')
  next(reader, None)  # skip the header

  cnt = 0

  for row in reader:
    cnt += 1
    tgn_uri = row[0]
    pleiades_uri = row[1]
    tgn_label = row[2]

    output.write('<' + tgn_uri + '> a lawd:Place ;\n')
    output.write('  rdfs:label "' + tgn_label + '" ;\n')
    output.write('  skos:closeMatch <' + pleiades_uri + '> ;\n')
    output.write('  .\n\n')

  print('Converted ' +  str(cnt) + ' records')
  output.close()
