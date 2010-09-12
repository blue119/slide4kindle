#!/bin/sh
# step-0 : check suffix if file is not pdf format. convert it to pdf by unoconv
# step-1 : convert pdf to png
# step-2 : resize png let it fit in with kindle screen
# step-3 : combination

version="0.1"
file="$1"
tmp_folder="/tmp/$$"
support_suffix_list=('ppt' 'pdf' 'odp')
kindle_scale="1.35"
store=$(pwd)

prefix=`echo ${file} | cut -d'.' -f1`;
suffix=`echo ${file} | cut -d'.' -f2`;

function debug()
{
	#echo $@
	print
}

function suffix_check()
{
	for i in ${support_suffix_list[@]}
	do
		if test "$i" == "$1"; then
			return
		fi
	done
	echo "sorry!! it only support ${support_suffix_list[@]}"
	exit
}

#step-0
suffix_check ${suffix}
if [ -f ${tmp_folder} ]; then
	debug "Folder Exist"
	rm -f ${tmp_folder}
else
	debug "Folder don't Exist"
fi

# create temp folder for process
echo -ne "Create tmp folder: ${tmp_folder}\n"
mkdir ${tmp_folder}

# copy file to tmp Folder
cp ${file} ${tmp_folder}
cd ${tmp_folder}

if [ "${suffix}" != "pdf" ]; then
	unoconv -f pdf ${file}
	file="${prefix}.pdf"
fi

#step_1
echo -ne "convert ${file} --> $prefix.png\n"
convert -interlace none ${file} ${prefix}.png

#step_2
file_num=$(ls *.png | wc -l)
debug "file_size: ${file_num}"
slide_list=`for (( i=0; i<${file_num}; i++)); do
	echo "${prefix}-$i.png"
done
`

image_w=`identify -format "%w" ${prefix}-0.png`
image_h=`identify -format "%h" ${prefix}-0.png`

ori_scale=`bc << EOF
scale=3
${image_w} / ${image_h}
EOF
`
debug "ori scale" ${ori_scale}

extent_w=`bc << EOF
scale=0
${kindle_scale} * ${image_h}
EOF
`
debug "w extent to: ${extent_w}"

total_pixel=`bc << EOF
scale=0
${extent_w} * ${image_h}
EOF
`

#image resize
echo -ne "image resize to ${extent_w}x${image_h}\n"
for i in ${slide_list}; do
	convert $i -thumbnail ${total_pixel}@ -gravity center -background white -extent ${extent_w}x${image_h} $i
done

#step_3
echo -ne "composing to ${prefix}_kindle.pdf\n"
convert ${slide_list} ${prefix}_kindle.pdf

#final
cp ${prefix}_kindle.pdf ${store}
# echo -ne "Del tmp folder\n"
# rm -rf ${tmp_folder}


