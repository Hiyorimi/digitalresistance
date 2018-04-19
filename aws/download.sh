rm -rf rkn
mkdir rkn
curl -k -X GET -H "Authorization: Bearer %TOKEN_SPROSI_U_DUROVA" %URL_SPROSI_U_DUROVA > ./rkn/rkn.zip
cd rkn
unzip rkn.zip