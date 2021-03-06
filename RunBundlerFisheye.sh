#!/bin/bash
#
# RunBundler.sh
#   copyright 2008 Noah Snavely
#
# A script for preparing a set of image for use with the Bundler 
# structure-from-motion system.
#
# Usage: RunBundler.sh [image_dir]
#
# The image_dir argument is the directory containing the input images.
# If image_dir is omitted, the current directory is used.
#

# Set this variable to your base install path (e.g., /home/foo/bundler)
# BASE_PATH="TODO"
BASE_PATH=$(dirname $(which $0));

if [ $BASE_PATH == "TODO" ]
then
    echo "Please modify this script (RunBundler.sh) with the base path of your bundler installation.";
    exit;
fi

######################################################################
# For the latest version of the bundler
# if [ $MACHTYPE == "x86_64" ]
# then
# MKL_PATH=/projects/grail/grail74/snavely/intel/mkl/10.0.011/lib/em64t
# IPP_PATH=/projects/grail/grail74/snavely/intel/ipp/5.3/em64t/sharedlib
# else
# MKL_PATH=/projects/grail/grail74/snavely/intel/mkl/10.0.011/lib/32
# IPP_PATH=/projects/grail/grail74/snavely/intel/ipp/5.3/ia32/sharedlib
# fi


rm *.fd.*
rm *.rd.*

EXTRACT_FOCAL=$BASE_PATH/bin/extract_focal.pl

OS=`uname -o`

if [ $OS == "Cygwin" ]
then
    MATCHKEYS=$BASE_PATH/bin/KeyMatchFull.exe
    BUNDLER=$BASE_PATH/bin/Bundler.exe
else
    MATCHKEYS=$BASE_PATH/bin/KeyMatchFull
    BUNDLER=$BASE_PATH/bin/bundler
fi

TO_SIFT=$BASE_PATH/bin/ToSift.sh

IMAGE_DIR="."

if [ $# -eq 1 ]
then
    echo "Using directory '$1'"
    IMAGE_DIR=$1
fi

# Rename ".JPG" to ".jpg"
for d in `ls -1 $IMAGE_DIR | egrep ".JPG$"`
do 
    mv $IMAGE_DIR/$d $IMAGE_DIR/`echo $d | sed 's/\.JPG/\.jpg/'`
done

# Create the list of images
find $IMAGE_DIR -maxdepth 1 | egrep ".jpg$" | sort > list_tmp.txt
$EXTRACT_FOCAL list_tmp.txt
cp prepare/list.txt .

# Run the ToSift script to generate a list of SIFT commands
echo "[- Extracting keypoints -]"
rm -f sift.txt
$TO_SIFT $IMAGE_DIR > sift.txt 

# Execute the SIFT commands

SIFT_COUNT=`ls -l *.key.gz | wc -l` 
echo sift count is $SIFT_COUNT

if [ $SIFT_COUNT -eq 0 ]
then
	sh sift.txt
else
	echo "SIFT Files detected skipping...."
fi

# Match images (can take a while)
echo "[- Matching keypoints (this can take a while) -]"
sed 's/\.jpg$/\.key/' list_tmp.txt > list_keys.txt
sleep 1

MATCH_COUNT=`ls -l matches.init.txt | wc -l` 
echo Matching count is $MATCH_COUNT

if [ $MATCH_COUNT -eq 0 ]
then
	echo $MATCHKEYS list_keys.txt matches.init.txt
	$MATCHKEYS list_keys.txt matches.init.txt
fi

# Generate the options file for running bundler 
mkdir bundle
rm -f options.txt

echo "--match_table matches.init.txt" >> options.txt
echo "--output bundle.out" >> options.txt
echo "--output_all bundle_" >> options.txt
echo "--output_dir bundle" >> options.txt
echo "--variable_focal_length" >> options.txt
echo "--use_focal_estimate" >> options.txt
echo "--constrain_focal" >> options.txt
echo "--constrain_focal_weight 0.0001" >> options.txt
echo "--estimate_distortion" >> options.txt
echo "--run_bundle" >> options.txt
echo "--fisheye fisheye.txt" >> options.txt
#echo "--slow_bundle" >> options.txt

#echo "--match_table matches.init.txt " >> options.txt
#echo "--output bundle.out" >> options.txt
#echo "--output_all bundle_" >> options.txt
#echo "--output_dir bundle" >> options.txt
#echo "--init_focal_length 1000" >> options.txt
#echo "--variable_focal_length" >> options.txt
#echo "--projection_estimation_threshold 4.0" >> options.txt
#echo "--run_bundle" >> options.txt
#echo "--use_focal_estimate" >> options.txt
#echo "--min_camera_distance_ratio 0.0" >> options.txt
#echo "--ray_angle_threshold 3.0" >> options.txt
#echo "--fisheye Sigma8mm.txt" >> options.txt
#echo "--init_pair1 0" >> options.txt
#echo "--init_pair2 1" >> options.txt

FOCAL=`cat fisheye.txt | grep FisheyeFocal | awk '{print $2}'`
awk '{ print $1 " 1 " FF }' FF=$FOCAL list.txt > list1.txt


# Run Bundler!
echo "[- Running Bundler -]"
rm -f constraints.txt
rm -f pairwise_scores.txt
$BUNDLER list1.txt --options_file options.txt > bundle/out

echo "[- Done -]"


Bundle2PMVS list.txt bundle/bundle.out
FisheyeBundle2PMVS.sh
sh prepfisheye_pmvs.sh
cd pmvs
~/pmvs3/matchp-64 ./ options.txt
cd ..



