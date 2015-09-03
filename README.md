#SURPI-v1.0.7 (April 2014)

**Note**: For the most up to date version of the SURPI source code, go to this website: [http://chiulab.ucsf.edu/surpi](http://chiulab.ucsf.edu/surpi "surpi").

SURPI has been tested on Ubuntu 12.04. It will likely function properly on other Linux distributions, but this has not been tested.

###Hardware Requirements:

SURPI requires a machine with high RAM in order to run efficiently. This is mainly due to SNAP, which gains its speed by loading the reference databases completely into RAM. We’ve run SURPI successfully on machines with **60.5 GB** RAM. SURPI will use all cores on a machine by default, though the number of cores used can be adjusted within the config file. Much of SURPI is parallelized, so it benefits from using as many cores as possible.


###Installation:


#####Install all software dependencies

* [fastQValidator](http://genome.sph.umich.edu/wiki/FastQValidator)
* [Minimo (v1.6)](http://sourceforge.net/projects/amos/files/amos/3.1.0/)
* [Abyss (v1.3.5)](http://www.bcgsc.ca/platform/bioinfo/software/abyss)
* [RAPSearch (v2.12)](http://omics.informatics.indiana.edu/mg/RAPSearch2/)
* [seqtk (v 1.0r31)](https://github.com/lh3/seqtk)
* [SNAP (v0.15)](http://snap.cs.berkeley.edu)
* [gt (v1.5.1)](http://genometools.org/index.html)
* [fastq](https://github.com/brentp/bio-playground/tree/master/reads-utils)
* [fqextract](https://gist.github.com/drio/1168330)
* [cutadapt (v1.2.1)](https://code.google.com/p/cutadapt/)
* [prinseq-lite.pl](http://prinseq.sourceforge.net)
* [dropcache](http://stackoverflow.com/questions/13646925/allowing-a-non-root-user-to-drop-cache)

#####Decompress SURPI package

Decompress SURPI and place all files into a directory included in your $PATH. Something like the following should work:

	tar xvfz SURPI.tar.gz

#####Create the databases

1. SNAP Databases:

    * Human DB
    * NCBI nr DB (Comprehensive Mode)
    * Viral protein DB (Comprehensive Mode)
    * NCBI nt DB (Comprehensive Mode)
    * Viral nt DB (Fast Mode)
    * Bacterial DB (Fast Mode)
	
2. Taxonomy Databases (generated with `create_taxonomy_db.sh`)
    * gi_taxid_prot.db
    * gi_taxid_nucl.db
    * names_nodes_scientific.db

#####Customize certain SURPI files

Below are some notes on files that may need to be modified to run
SURPI:

* `cutadapt_quality.csh`: specify location of /tmp folder

    cutadapt_quality.csh defaults to using /tmp for temporary file
    storage. If using a system with limited space in this location,
    change the location to a directory with more storage space
    available.

* `taxonomy_lookup_embedded.pl`

    Set database_directory to the location of the taxonomy
    databases created below.

* `tweet.pl`

    SURPI has the ability to send out notifications via Twitter
    at various stages within the pipeline. If this feature is
    desired, you will need to set up a Twitter application within
    your account for this purpose. See
    [https://dev.twitter.com/apps](https://dev.twitter.com/apps)
    for more details.

    Once an application has been set up, fill in the below parameters
    to the `tweet.pl` program.

    * consumer_key
    * consumer_secret
    * oauth_token
    * oauth_token_secret

* perl modules to install

    * Net::Twitter::Lite::WithAPIv1_1
    * Net::OAuth

#####Run SURPI


To run SURPI, execute the following in a directory containing
your FASTQ input file.

1. This command will create the necessary config file to run SURPI:

        SURPI.sh -z <INPUTFILE>

    After typing the above line, a config file and a “go” file will
    be created. The config file will contain default values for many
    parameters - these parameters may need to be modified depending
    on your environment. The config file has descriptions of the
    options allowed by SURPI.

2. Once the config file has been customized, the SURPI pipeline
can be initiated by typing in the name of the go file that was
created. Below is an example (boldfaced text is inputted by the
user):

	    sfederman@tribble:/data/inputfile/test$ ls -laF
	    total 750212
	    drwxrwxr-x  2 sfederman sfederman      4096 Jan 20 16:45 ./
	    drwxrwxr-x 11 sfederman sfederman     61440 Jan 20 16:45 ../
	    -rw-rw-r--  1 sfederman sfederman 768143660 Jan 20 16:45 inputfile.fastq

        sfederman@tribble:/data/inputfile/test$ SURPI.sh -z inputfile.fastq
        inputfile.config generated. Please edit it to contain the proper parameters for your analysis. go_ inputfile generated. Initiate the pipeline by running this program. (./go_inputfile)

	    sfederman@tribble:/data/inputfile/test$ ls -laF
	    total 750220
	    drwxrwxr-x  2 sfederman sfederman      4096 Jan 20 16:47 ./
	    drwxrwxr-x 11 sfederman sfederman     61440 Jan 20 16:45 ../
	    -rw-rw-r--  1 sfederman sfederman      1976 Jan 20 16:47 inputfile.config
	    -rw-rw-r--  1 sfederman sfederman 768143660 Jan 20 16:45 inputfile.fastq
	    -rwxrwxr-x  1 sfederman sfederman        84 Jan 20 16:47 go_inputfile*
	    
	    sfederman@tribble:/data/inputfile/test$ ./go_inputfile &

	    Progression of the pipeline can be followed by monitoringthe log file (titled inputfile.SURPI.log, in the above example). We have also find it useful to monitor the status of the pipeline with the program htop.

