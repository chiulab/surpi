#!/usr/bin/python
#
#	create_taxonomy_db.py
#
#	This program creates the SQLite taxonomy database used by SURPI
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 7/2/2014

import sqlite3

# Create names_nodes_scientific.db
print ("Creating names_nodes_scientific.db...")
conn = sqlite3.connect('names_nodes_scientific.db')
c = conn.cursor()
c.execute('''CREATE TABLE names (
			taxid INTEGER PRIMARY KEY,
			name TEXT)''')

with open('names_scientificname.dmp', 'r') as map_file:
	for line in map_file:
		line = line.split("|")
		taxid = line[0].strip()
		name = line[1].strip()

		c.execute ("INSERT INTO names VALUES (?,?)", (taxid, name))

d = conn.cursor()
d.execute('''CREATE TABLE nodes (
			taxid INTEGER PRIMARY KEY,
			parent_taxid INTEGER,
			rank TEXT)''')

with open('nodes.dmp', 'r') as map_file:
	for line in map_file:
		line = line.split("|")
		taxid = line[0].strip()
		parent_taxid = line[1].strip()
		rank = line[2].strip()

		d.execute ("INSERT INTO nodes VALUES (?,?,?)", (taxid, parent_taxid, rank))
conn.commit()
conn.close()

# Create gi_taxid_nucl.db
print ("Creating gi_taxid_nucl.db...")
conn = sqlite3.connect('gi_taxid_nucl.db')
c = conn.cursor()
c.execute('''CREATE TABLE gi_taxid (
			gi INTEGER PRIMARY KEY,
			taxid INTEGER)''')

with open('gi_taxid_nucl.dmp', 'r') as map_file:
	for line in map_file:
		line = line.split()
		c.execute("INSERT INTO gi_taxid VALUES ("+line[0]+","+line[1]+")")
conn.commit()
conn.close()

# Create gi_taxid_prot.db
print ("Creating gi_taxid_prot.db...")
conn = sqlite3.connect('gi_taxid_prot.db')
c = conn.cursor()
c.execute('''CREATE TABLE gi_taxid (
			gi INTEGER PRIMARY KEY,
			taxid INTEGER)''')

with open('gi_taxid_prot.dmp', 'r') as map_file:
	for line in map_file:
		line = line.split()
		c.execute("INSERT INTO gi_taxid VALUES ("+line[0]+","+line[1]+")")

conn.commit()
conn.close()
