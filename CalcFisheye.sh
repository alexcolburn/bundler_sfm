#!/bin/bash
#
# CalcFisheye.sh
# Create fisheye correction for SIGMA 8mm

I=`ls *.jpg | head -n 1`


jhead $I | grep Resolution | awk '{ R=($3/3072); CX=13.6; CY=0.08; FR=1520; FF=700; \
print  "FisheyeCenter: " CX*R "  " CY*R; \
print  "FisheyeRadius: " FR*R; \
print  "FisheyeAngle: 175"; \
print  "FisheyeFocal: " FF*R; \
print  "FisheyeModel: 1" \
print  "cropFactor: 0.64" \
}'  



#Focal for 3x2K
#echo "FisheyeCenter: 13.6 0.08" 
#echo "FisheyeRadius: 1520"
#echo "FisheyeAngle: 180" 
#echo "FisheyeFocal: 700" 

#FF=`grep FisheyeFocal Sigma8mm.txt | awk '{print $2}'`
#echo $FF
#awk '{ print $1 " 1 " ff }' ff=$FF list.txt > list1.txt

