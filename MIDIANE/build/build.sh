rm MIDIANE.ane
unzip -o MIDIANE.swc
rm -r -f mac
mkdir mac
cp -L -R "../mac/MIDIANE/build/Release/" mac
cp library.swf mac
"/Applications/Adobe Flash Builder 4.7/eclipse/plugins/com.adobe.flash.compiler_4.7.0.349722/AIRSDK/bin/adt" -package -target ane MIDIANE.ane extension.xml -swc MIDIANE.swc -platform MacOS-x86 -C mac . 
