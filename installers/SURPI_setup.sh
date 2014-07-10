#!/bin/bash
#
#	SURPI_setup.sh
#
#	This script will install SURPI and its dependencies. It has been tested with Ubuntu 12.04.
#	The script has been designed to work on a newly installed OS, though should also work on an existing system.
#
#	Several Ubuntu packages are installed, as well as some perl modules - please inspect the code if you have concerns
#	about these installations on an existing system.
#
#	SURPI is sensitive to the use of specific versions of its software dependencies. We will likely work to validate
#	new versions over time, but currently we are using specific versions for these dependencies. These versions may
#	conflict with versions on an existing system.
#
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# Permission to copy and modify is granted under the BSD license
# Last revised 6/6/2014

export DEBIAN_FRONTEND=noninteractive

#Change below folders as desired in order to change installation location.
install_folder="/usr/local"
bin_folder="$install_folder/bin"

if [ ! -d $bin_folder ]
then
	mkdir $bin_folder
fi

CWD=$(pwd)

#
##
### install & update Ubuntu packages
##
#

# Install packages necessary for the SURPI pipeline.
sudo -E apt-get update -y
sudo -E apt-get install -y make csh htop python-dev gcc unzip g++ cpanminus ghostscript blast2 python-matplotlib git pigz parallel
sudo -E apt-get upgrade -y

#
##
### install EC2 CLI tools
##
#

sudo -E apt-get install -y openjdk-7-jre
wget http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip
sudo mkdir /usr/local/ec2
sudo unzip ec2-api-tools.zip -d /usr/local/ec2

echo "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre" >> ~/.bashrc
echo "export EC2_HOME=/usr/local/ec2/ec2-api-tools-1.6.13.0/" >> ~/.bashrc
echo "PATH=\$PATH:$EC2_HOME/bin" >> ~/.bashrc

#
##
### install Perl Modules
##
#

# for taxonomy
sudo cpanm DBI
sudo cpanm DBD::SQLite

# for twitter updates
sudo cpanm Net::Twitter::Lite::WithAPIv1_1
sudo cpanm Net::OAuth


#
##
### install SURPI scripts
##
#

#Install via git clone
# cd $bin_folder
# sudo git clone https://github.com/chiulab/surpi.git
# cd $CWD

#Install specific version
version="surpi-1.0.18"
wget "https://github.com/chiulab/surpi/releases/download/v1.0.18/$version.tar.gz"
tar xvfz $version.tar.gz
sudo mv $version "$bin_folder/"
sudo ln -s "$bin_folder/$version" "$bin_folder/surpi"

echo "PATH=\$PATH:$bin_folder" >> ~/.bashrc
echo "PATH=\$PATH:$bin_folder/surpi" >> ~/.bashrc

#
##
### install gt (genometools)
##
#
curl -O "http://genometools.org/pub/genometools-1.5.1.tar.gz"
tar xvfz genometools-1.5.1.tar.gz
cd genometools-1.5.1
make 64bit=yes curses=no cairo=no
sudo make prefix=$install_folder 64bit=yes curses=no cairo=no install
cd $CWD

#
##
### install seqtk
##
#
# 6/4/14 - discovered that current version of seqtk (1.0-r57) is buggy. We should install 1.0-r31
curl "https://codeload.github.com/lh3/seqtk/zip/1.0" > seqtk.zip
unzip seqtk.zip
cd seqtk-1.0
make
sudo mv seqtk "$bin_folder/"
cd $CWD

#
##
### install fastq
##
#
mkdir fastq
cd fastq
wget "https://raw.github.com/brentp/bio-playground/master/reads-utils/fastq.cpp"
g++ -O2 -o fastq fastq.cpp
sudo mv fastq "$bin_folder/"
sudo chmod +x "$bin_folder/fastq"
cd $CWD

#
##
### install fqextract
##
#
mkdir fqextract
cd fqextract
wget https://raw.github.com/attractivechaos/klib/master/khash.h
wget http://chiulab.ucsf.edu/SURPI/software/fqextract.c
gcc fqextract.c -o fqextract
sudo mv fqextract "$bin_folder/"
sudo chmod +x "$bin_folder/fqextract"
cd $CWD

#
##
### install cutadapt
##
#
curl -O "https://cutadapt.googlecode.com/files/cutadapt-1.2.1.tar.gz"
tar xvfz cutadapt-1.2.1.tar.gz
cd cutadapt-1.2.1
python setup.py build
sudo python setup.py install
cd $CWD

#
##
### install prinseq-lite.pl
##
#

curl -O "http://iweb.dl.sourceforge.net/project/prinseq/standalone/prinseq-lite-0.20.3.tar.gz"
tar xvfz prinseq-lite-0.20.3.tar.gz
sudo cp prinseq-lite-0.20.3/prinseq-lite.pl "$bin_folder/"
sudo chmod +x "$bin_folder/prinseq-lite.pl"

#
##
### compile and install dropcache (must be after SURPI scripts)
##
#

sudo gcc $bin_folder/surpi/source/dropcache.c -o dropcache
sudo mv dropcache "$bin_folder/"
sudo chown root "$bin_folder/dropcache"
sudo chmod u+s "$bin_folder/dropcache"

#
##
### install SNAP
##
#

curl -O "http://snap.cs.berkeley.edu/downloads/snap-0.15.4-linux.tar.gz"
tar xvfz snap-0.15.4-linux.tar.gz
sudo cp snap-0.15.4-linux/snap "$bin_folder/"

#
##
### install RAPSearch
##
#

curl "http://omics.informatics.indiana.edu/mg/get.php?justdoit=yes&software=rapsearch2.12_64bits.tar.gz" > rapsearch2.12_64bits.tar.gz
tar xvfz rapsearch2.12_64bits.tar.gz
cd RAPSearch2.12_64bits
./install
sudo cp bin/* "$bin_folder/"
cd $CWD

#
##
### install fastQValidator from sourcecode
##
#
# http://genome.sph.umich.edu/wiki/FastQValidator

curl -O "http://genome.sph.umich.edu/w/images/2/20/FastQValidatorLibStatGen.0.1.1a.tgz"
tar xvf FastQValidatorLibStatGen.0.1.1a.tgz
cd fastQValidator_0.1.1a
make all
sudo cp fastQValidator/bin/fastQValidator "$bin_folder/"
cd $CWD


#
##
### install AbySS
##
#
# http://www.bcgsc.ca/platform/bioinfo/software/abyss

#Download ABySS
wget "http://www.bcgsc.ca/platform/bioinfo/software/abyss/releases/1.3.5/abyss-1.3.5.tar.gz"
tar xvfz abyss-1.3.5.tar.gz

#Set up Boost Dependency
cd abyss-1.3.5
wget "http://downloads.sourceforge.net/project/boost/boost/1.50.0/boost_1_50_0.tar.bz2"
tar jxf boost_1_50_0.tar.bz2
ln -s boost_1_50_0/boost boost

#Install packaged dependencies
sudo apt-get install -y openmpi-bin sparsehash libopenmpi-dev

# Configure ABySS
./configure --with-mpi=/usr/lib/openmpi CPPFLAGS=-I/usr/include/google
make
sudo make install
cd $CWD

#
##
### install Minimo
##
#

sudo apt-get -y install mummer
sudo cpanm DBI
sudo cpanm Statistics::Descriptive
sudo cpanm XML::Parser

curl -O "http://iweb.dl.sourceforge.net/project/amos/amos/3.1.0/amos-3.1.0.tar.gz"
tar xvfz amos-3.1.0.tar.gz
cd amos-3.1.0
./configure --prefix=$install_folder
make
sudo make install
cd $CWD
