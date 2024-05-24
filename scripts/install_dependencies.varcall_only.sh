#!/usr/bin/env bash
set -vexu

install_root=$1

# We need packages from universe, so make sure it's added
# (it isn't for singularity)
apt-get update
apt-get install -y software-properties-common
apt-add-repository universe
apt-add-repository multiverse
apt-get update
apt-get upgrade -y

DEBIAN_FRONTEND=noninteractive apt-get install -y \
  automake \
  build-essential \
  cmake \
  curl \
  gawk \
  git \
  libbz2-dev \
  libcurl4-gnutls-dev \
  libhts-dev \
  libssl-dev \
  libncurses5-dev \
  libncursesw5-dev \
  libvcflib-tools \
  liblzma-dev \
  openjdk-17-jre \
  pkg-config \
  python3-pip \
  unzip \
  r-base-core \
  wget \
  zlib1g-dev


mkdir $install_root
cd $install_root

#_________________________ bcftools _______________________#
cd $install_root
wget -q https://github.com/samtools/bcftools/releases/download/1.15.1/bcftools-1.15.1.tar.bz2
tar xf bcftools-1.15.1.tar.bz2
rm bcftools-1.15.1.tar.bz2
cd bcftools-1.15.1/
make
make install
cd ..
rm -rf bcftools-1.15.1

#_________________________ fqtools ________________________#
cd $install_root
wget -q https://github.com/alastair-droop/fqtools/archive/986e451.tar.gz
tar xf 986e451.tar.gz
rm 986e451.tar.gz
cd fqtools-986e451/
make
cd ..
cp -s fqtools-986e451/bin/fqtools .

#------------------------------ minimap2 ---------------------------------------
cd $install_root
MINIMAP2_V=2.24
wget https://github.com/lh3/minimap2/releases/download/v${MINIMAP2_V}/minimap2-${MINIMAP2_V}.tar.bz2
tar xf minimap2-${MINIMAP2_V}.tar.bz2
rm minimap2-${MINIMAP2_V}.tar.bz2
cd minimap2-${MINIMAP2_V}
arch_is_arm=$(dpkg --print-architecture | grep '^arm' | wc -l)
if [[ $arch_is_arm -gt 0 ]]
then
    make arm_neon=1 aarch64=1
else
    make
fi
cd ..
cp -s minimap2-${MINIMAP2_V}/minimap2 .


#________________________ seqtk __________________________#
cd $install_root
wget -q https://github.com/lh3/seqtk/archive/v1.2.tar.gz
tar xf v1.2.tar.gz
rm v1.2.tar.gz
cd seqtk-1.2/
make
cd ..
cp -s seqtk-1.2/seqtk .

#_________________________ samtools ______________________#
cd $install_root
wget -q https://github.com/samtools/samtools/releases/download/1.15.1/samtools-1.15.1.tar.bz2
tar xf samtools-1.15.1.tar.bz2
rm samtools-1.15.1.tar.bz2
cd samtools-1.15.1/
make
make install
cd ..
rm -rf samtools-1.15.1


#________________________ Trimmomatic ____________________#
cd $install_root
wget -q http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.36.zip
unzip Trimmomatic-0.36.zip
rm Trimmomatic-0.36.zip


#________________________ cortex _________________________#
cd $install_root
git clone --recursive https://github.com/iqbal-lab/cortex.git
cd cortex
git checkout c8147152cd4015c45057900e8fb600376d1d7fb3
bash install.sh
make NUM_COLS=1 cortex_var
make NUM_COLS=2 cortex_var
rm -rf .git

# ___________________ python packages ___________________#
# note: requests needs to be here instead of as part of
# python setup.py install, because setup.py install
# throws an error.  This way works.
pip3 install cython
pip3 install python-dateutil requests pysam pyfastaq pymysql numpy openpyxl pyflakes scipy XlsxWriter


#________________________ vcftools _______________________#
cd $install_root
wget -q https://github.com/vcftools/vcftools/releases/download/v0.1.15/vcftools-0.1.15.tar.gz
tar xf vcftools-0.1.15.tar.gz
rm vcftools-0.1.15.tar.gz
cd vcftools-0.1.15
./configure --prefix $PWD/install
make
make install
rm -rf src/cpp
#
# cortex needs the perl/ directory. It expects it to be in the vcftools root,
# but somehwere between v0.1.9 and v0.1.15 it moved into src/.
ln -s src/perl/ .

#________________________ gramtools _________________________#
cd $install_root
# Why six>=1.14.0?
# See https://github.com/pypa/virtualenv/issues/1551
pip3 install tox "six>=1.14.0"
git clone https://github.com/iqbal-lab-org/gramtools
cd gramtools
git checkout 8af53f6c8c0d72ef95223e89ab82119b717044f2
# Note: a simple "pip3 install ." works for singularity but
# not for docker - the `gram` exectuable does not get
# put where gramtools expects to find it. The method
# below, which explicitly builds the binary, then installs
# does work ok for both docker and singularity.
mkdir cmake-build
cd cmake-build
cmake .. -DCMAKE_BUILD_TYPE=REL_WITH_ASSERTS
make gram
cd ..
pip3 install -e .
rm -rf cmake-build .git

#________________________ vt __________________________________#
cd $install_root
git clone https://github.com/atks/vt.git vt-git
cd vt-git
git checkout 2187ff6347086e38f71bd9f8ca622cd7dcfbb40c
make
rm -rf .git
cd ..
cp -s vt-git/vt .



#________________________ minos _____________________________#
pip3 install 'cluster_vcf_records==0.13.3'
pip3 install git+https://github.com/iqbal-lab-org/minos@v0.12.5


