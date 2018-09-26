#!/bin/sh
#
#
#
#

DICT_BUILD_TOOL_BIN=$(cd "$(dirname "$0")"; pwd)		# The directory that contains this script.


do_add_supplementary_key=${do_add_supplementary_key:-1}
preserve_unused_ref_id_in_reference_index=${preserve_unused_ref_id_in_reference_index:-0}

COMPRESS_OPT=
COMPRESS_SETTING=0
ENCRYPT_OPT=
ENCRYPT_SETTING=0
TRIE_OPT=
TRIE_SETTING=0
COMPATIBLE_VERS="10.5"

while getopts c:e:s:t:v: opt
do
	case $opt in
	c)
		COMPRESS_SETTING=$OPTARG
		COMPRESS_OPT="-c $COMPRESS_SETTING"
		;;
	e)
		ENCRYPT_SETTING=$OPTARG
		ENCRYPT_OPT="-e $ENCRYPT_SETTING"
		;;
	s)
		NORMALIZE_SETTING=$OPTARG
		if [ $NORMALIZE_SETTING -eq 0 ]
		then
			do_add_supplementary_key=0
		fi
		;;
	t)
		TRIE_SETTING=$OPTARG
		;;
	v)
		COMPATIBLE_VERS=$OPTARG
		;;
	esac
done
shift $((OPTIND - 1))

DICT_NAME="$1"
SRC_FILE="$2"
CSS_NAME="$3"
PLIST_NAME="$4"

#Fix outdated options of our dictionaries (should be removed after dictionaries updated)
if [ $COMPRESS_SETTING -eq 2 ] && [ $TRIE_SETTING -gt 0 ] && [ $COMPATIBLE_VERS = "10.5" ]; then
	COMPATIBLE_VERS="10.6"
fi

#Set suitable default and fix invalid options for specified system version
if [ $COMPATIBLE_VERS = "10.5" ]; then
	if [ $COMPRESS_SETTING -gt 1 ]; then
		COMPRESS_OPT="-c 1"
	fi
	TRIE_OPT=""
elif [ $COMPATIBLE_VERS = "10.6" ] || [ $COMPATIBLE_VERS = "10.11" ]; then
	if [ $TRIE_SETTING -eq 0 ]; then
		TRIE_OPT="-t 1"
	elif [ $TRIE_SETTING -eq 1 ]; then
		TRIE_OPT="-t 2"
	elif [ $TRIE_SETTING -eq 2 ]; then
		TRIE_OPT="-t 3"
	fi
	if [ ! -n "$COMPRESS_OPT" ]; then
		COMPRESS_OPT="-c 2"
	fi
else
	echo "Error." 1>&2
	exit 1
fi

CONTENTS_DATA_PATH=Contents
if [ $COMPATIBLE_VERS = "10.11" ]; then
	CONTENTS_DATA_PATH="Contents/Resources"
fi

DICT_DEV_KIT_OBJ_DIR=${DICT_DEV_KIT_OBJ_DIR:-objects}
export DICT_DEV_KIT_OBJ_DIR

OBJECTS_DIR=$DICT_DEV_KIT_OBJ_DIR

OTHER_RSRC_DIR="OtherResources"

BODY_DATA_NAME=Body.data
KEY_TEXT_INDEX_NAME=KeyText.index
ENTRY_ID_INDEX_NAME=EntryID.index

########

error()
{
	echo "$@" 1>&2
	exit 1
}

########
echo "- Building $DICT_NAME.dictionary."

# Check source XML.
echo "- Checking source."
xmllint --stream -noout "$SRC_FILE" || error "Error."

# Prepare directory.
echo "- Cleaning objects directory."
rm -rf "$OBJECTS_DIR"
mkdir -p $OBJECTS_DIR

# Make dictionary bundle.
echo "- Preparing dictionary template."
plutil -s "$PLIST_NAME" || error "Error."
tr "\r" "\n" < "$PLIST_NAME" > $OBJECTS_DIR/dict.plist || error "Error."

# Merge property to dictionary template.
xsltproc "$DICT_BUILD_TOOL_BIN"/extract_property.xsl "$OBJECTS_DIR"/dict.plist > "$OBJECTS_DIR"/dict_prop_list.txt || error "Error."
rm "$OBJECTS_DIR"/dict.plist
IDX_DICT_VERS=""
if [ $COMPATIBLE_VERS = "10.11" ]; then
	IDX_DICT_VERS="-v 3"
fi
"$DICT_BUILD_TOOL_BIN"/generate_dict_template.sh $COMPRESS_OPT $ENCRYPT_OPT $TRIE_OPT $IDX_DICT_VERS "$OBJECTS_DIR"/dict_prop_list.txt > "$OBJECTS_DIR"/customized_template.plist || error "Error."
plutil -s "$OBJECTS_DIR"/customized_template.plist || error "Error."
rm "$OBJECTS_DIR"/dict_prop_list.txt

# Preprocess sources.
echo "- Preprocessing dictionary sources."
tr "\r" "\n" < "$SRC_FILE" > "$OBJECTS_DIR"/dict.xml || error "Error."
# Replace localizable <index> format to the standard one
sed 's/<d:index>[[:blank:]\n]*<d:index_value>\([^<]*\)<\/d:index_value>[[:blank:]\n]*<d:index_title>\([^<]*\)<\/d:index_title>[[:blank:]\n]*<\/d:index>/<d:index d:value="\1" d:title="\2"\/>/g' $OBJECTS_DIR/dict.xml > $OBJECTS_DIR/dict_mod.xml || error "Error."
rm "$OBJECTS_DIR"/dict.xml
"$DICT_BUILD_TOOL_BIN"/make_line.pl "$OBJECTS_DIR"/dict_mod.xml > "$OBJECTS_DIR"/dict.formattedSource.xml || error "Error."
rm "$OBJECTS_DIR"/dict_mod.xml
"$DICT_BUILD_TOOL_BIN"/make_body.pl "$OBJECTS_DIR"/dict.formattedSource.xml || error "Error."
# The make_body.pl creates $OBJECTS_DIR/dict.body and $OBJECTS_DIR/dict.offset


# Extract index data.
echo "- Extracting index data."
"$DICT_BUILD_TOOL_BIN"/extract_index.pl "$OBJECTS_DIR"/dict.formattedSource.xml > "$OBJECTS_DIR"/key_entry_list.txt || error "Error."
"$DICT_BUILD_TOOL_BIN"/extract_referred_id.pl "$OBJECTS_DIR"/dict.formattedSource.xml > "$OBJECTS_DIR"/referred_id_list.txt || error "Error."
"$DICT_BUILD_TOOL_BIN"/extract_front_matter_id.pl "$PLIST_NAME" >> "$OBJECTS_DIR"/referred_id_list.txt || error "Error."
rm "$OBJECTS_DIR"/dict.formattedSource.xml


########

# Prepare dictionary bundle.
echo "- Preparing dictionary bundle."
"$DICT_BUILD_TOOL_BIN"/make_dict_package "$OBJECTS_DIR"/dict.dictionary "$OBJECTS_DIR"/customized_template.plist || error "Error."
rm "$OBJECTS_DIR"/customized_template.plist

# Add body reocrd to dictionary.
echo "- Adding body data."
"$DICT_BUILD_TOOL_BIN"/add_body_record "$OBJECTS_DIR"/dict.dictionary $BODY_DATA_NAME "$OBJECTS_DIR"/dict.offsets "$OBJECTS_DIR"/dict.body > "$OBJECTS_DIR"/entry_body_list.txt || error "Error."
# rm "$OBJECTS_DIR"/dict.offsets
# rm "$OBJECTS_DIR"/dict.body


# Make key body matching list
echo "- Preparing index data."
"$DICT_BUILD_TOOL_BIN"/replace_entryid_bodyid.pl "$OBJECTS_DIR"/entry_body_list.txt < "$OBJECTS_DIR"/key_entry_list.txt > "$OBJECTS_DIR"/key_body_list.txt || error "Error."
rm "$OBJECTS_DIR"/key_entry_list.txt

# Normalize key_text
# "$DICT_BUILD_TOOL_BIN"/normalize_key_text.pl < $OBJECTS_DIR/key_body_list.txt > $OBJECTS_DIR/normalized_key_body_list.txt || error "Error."
"$DICT_BUILD_TOOL_BIN"/normalize_key_text < "$OBJECTS_DIR"/key_body_list.txt > "$OBJECTS_DIR"/normalized_key_body_list_1.txt || error "Error."
rm "$OBJECTS_DIR"/key_body_list.txt

if [ $do_add_supplementary_key -gt 0 ]
then
	"$DICT_BUILD_TOOL_BIN"/add_supplementary_key < "$OBJECTS_DIR"/normalized_key_body_list_1.txt > "$OBJECTS_DIR"/normalized_key_body_list_2.txt
	rm "$OBJECTS_DIR"/normalized_key_body_list_1.txt || error "Error."
else
	mv "$OBJECTS_DIR"/normalized_key_body_list_1.txt "$OBJECTS_DIR"/normalized_key_body_list_2.txt || error "Error."
fi

"$DICT_BUILD_TOOL_BIN"/remove_duplicate_key.pl < "$OBJECTS_DIR"/normalized_key_body_list_2.txt > "$OBJECTS_DIR"/normalized_key_body_list.txt
rm "$OBJECTS_DIR"/normalized_key_body_list_2.txt || error "Error."


# Add key_text index record to dictionary.
echo "- Building key_text index."
"$DICT_BUILD_TOOL_BIN"/build_key_index "$OBJECTS_DIR"/dict.dictionary $KEY_TEXT_INDEX_NAME "$OBJECTS_DIR"/normalized_key_body_list.txt $COMPATIBLE_VERS || error "Error."
# "$DICT_BUILD_TOOL_BIN"/add_key_index_record $OBJECTS_DIR/dict.dictionary $KEY_TEXT_INDEX_NAME $OBJECTS_DIR/normalized_key_body_list.txt || error "Error."
# rm $OBJECTS_DIR/normalized_key_body_list.txt

# Add entry_id index record to dictionary.
echo "- Building reference index."
if [ $preserve_unused_ref_id_in_reference_index -gt 0 ]
then
	"$DICT_BUILD_TOOL_BIN"/build_reference_index "$OBJECTS_DIR"/dict.dictionary $ENTRY_ID_INDEX_NAME "$OBJECTS_DIR"/entry_body_list.txt || error "Error."
else
	"$DICT_BUILD_TOOL_BIN"/pick_referred_entry_id.pl "$OBJECTS_DIR"/referred_id_list.txt < "$OBJECTS_DIR"/entry_body_list.txt > "$OBJECTS_DIR"/referred_entry_body_list.txt || error "Error."
	"$DICT_BUILD_TOOL_BIN"/build_reference_index "$OBJECTS_DIR"/dict.dictionary $ENTRY_ID_INDEX_NAME "$OBJECTS_DIR"/referred_entry_body_list.txt || error "Error."
fi
# "$DICT_BUILD_TOOL_BIN"/add_reference_index_record $OBJECTS_DIR/dict.dictionary $ENTRY_ID_INDEX_NAME $OBJECTS_DIR/entry_body_list.txt || error "Error."
# rm $OBJECTS_DIR/entry_body_list.txt

# Make the dictioanry read-only
echo "- Fixing dictionary property."
mv "$OBJECTS_DIR"/dict.dictionary/Contents/Info.plist "$OBJECTS_DIR"/Info.plist
plutil -convert xml1 "$OBJECTS_DIR"/Info.plist
"$DICT_BUILD_TOOL_BIN"/make_readonly.pl < "$OBJECTS_DIR"/Info.plist > "$OBJECTS_DIR"/dict.dictionary/Contents/Info.plist || error "Error."
rm "$OBJECTS_DIR"/Info.plist
plutil -convert binary1 "$OBJECTS_DIR"/dict.dictionary/Contents/Info.plist

# Copy other files.
echo "- Copying CSS."
cp -f "$CSS_NAME" "$OBJECTS_DIR"/dict.dictionary/"$CONTENTS_DATA_PATH"/DefaultStyle.css || error "Error."
if [ -d "$OTHER_RSRC_DIR" ] && [ -n "`ls $OTHER_RSRC_DIR`" ]
then
	echo "- Copying other resources."
	cp -XRf "$OTHER_RSRC_DIR"/* "$OBJECTS_DIR"/dict.dictionary/"$CONTENTS_DATA_PATH" || error "Error."
fi

mv -f "$OBJECTS_DIR"/dict.dictionary "$OBJECTS_DIR/$DICT_NAME.dictionary" || error "Error."

#
echo "- Finished building $OBJECTS_DIR/$DICT_NAME.dictionary."

