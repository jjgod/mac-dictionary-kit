#!/bin/sh
#
#
# generate_dict_template.sh
#

tool_vers=2
dictionary_vers=1

compress_body=1
body_id_size=4
encrypt_body=0
compress_triedata=0
burst_trie=0

COMPRESS_OPT=
ENCRYPT_OPT=
TRIE_OPT=

while getopts c:e:t: opt
do
	case $opt in
	c)
		COMPRESS_OPT=$OPTARG
		if [ $COMPRESS_OPT -eq 0 ]
		then
			compress_body=0
		elif [ $COMPRESS_OPT -eq 2 ]
		then
			compress_body=2
			body_id_size=8
			dictionary_vers=2
		fi
		;;
	e)
		ENCRYPT_OPT=$OPTARG
		if [ $ENCRYPT_OPT -gt 0 ]
		then
			encrypt_body=1
		fi
		;;
	t)
		TRIE_OPT=$OPTARG
		if [ $TRIE_OPT -gt 0 ]; then
			dictionary_vers=2
			burst_trie=1
			if [ $TRIE_OPT -eq 2 ]; then
				compress_triedata=1
			fi
		fi
		;;
	esac
done

shift $((OPTIND - 1))


PROP_LIST_FILE=$1


cat << END_OF_FILE
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
END_OF_FILE

cat $PROP_LIST_FILE

cat << END_OF_FILE
	<key>DCSDictionaryCSS</key>
	<string>DefaultStyle.css</string>
	<key>IDXDictionaryIndexes</key>
	<array>
		<dict>
			<key>IDXIndexAccessMethod</key>
			<string>com.apple.TrieAccessMethod</string>
			<key>IDXIndexBigEndian</key>
			<false/>
			<key>IDXIndexDataFields</key>
			<dict>
				<key>IDXExternalDataFields</key>
				<array>
					<dict>
						<key>IDXDataFieldName</key>
						<string>DCSExternalBodyID</string>
						<key>IDXDataSize</key>
						<integer>$body_id_size</integer>
						<key>IDXIndexName</key>
						<string>DCSBodyDataIndex</string>
					</dict>
				</array>
				<key>IDXFixedDataFields</key>
				<array>
					<dict>
						<key>IDXDataFieldName</key>
						<string>DCSPrivateFlag</string>
						<key>IDXDataSize</key>
						<integer>2</integer>
					</dict>
				</array>
				<key>IDXVariableDataFields</key>
				<array>
					<dict>
						<key>IDXDataFieldName</key>
						<string>DCSKeyword</string>
						<key>IDXDataSizeLength</key>
						<integer>2</integer>
					</dict>
					<dict>
						<key>IDXDataFieldName</key>
						<string>DCSHeadword</string>
						<key>IDXDataSizeLength</key>
						<integer>2</integer>
					</dict>
					<dict>
						<key>IDXDataFieldName</key>
						<string>DCSEntryTitle</string>
						<key>IDXDataSizeLength</key>
						<integer>2</integer>
					</dict>
					<dict>
						<key>IDXDataFieldName</key>
						<string>DCSAnchor</string>
						<key>IDXDataSizeLength</key>
						<integer>2</integer>
					</dict>
					<dict>
						<key>IDXDataFieldName</key>
						<string>DCSYomiWord</string>
						<key>IDXDataSizeLength</key>
						<integer>2</integer>
					</dict>
				</array>
			</dict>
			<key>IDXIndexDataSizeLength</key>
			<integer>2</integer>
			<key>IDXIndexKeyMatchingMethods</key>
			<array>
				<string>IDXExactMatch</string>
				<string>IDXPrefixMatch</string>
				<string>IDXCommonPrefixMatch</string>
				<string>IDXWildcardMatch</string>
				<string>IDXAllMatch</string>
			</array>
			<key>IDXIndexName</key>
			<string>DCSKeywordIndex</string>
			<key>IDXIndexPath</key>
			<string>KeyText.index</string>
			<key>IDXIndexSupportDataID</key>
			<false/>
			<key>IDXIndexWritable</key>
			<true/>
			<key>TrieAuxiliaryDataOptions</key>
			<dict>
				<key>IDXIndexPath</key>
				<string>KeyText.data</string>
END_OF_FILE

if [ $compress_triedata -gt 0 ]
then
cat << END_OF_FILE
				<key>HeapDataCompressionType</key>
				<integer>3</integer>
END_OF_FILE
fi

cat << END_OF_FILE
			</dict>
END_OF_FILE
			
if [ $burst_trie -gt 0 ]
then
cat << END_OF_FILE
			<key>TrieIndexCompressionType</key>
			<integer>1</integer>
END_OF_FILE
fi
			
cat << END_OF_FILE
		</dict>
		<dict>
			<key>IDXIndexAccessMethod</key>
			<string>com.apple.TrieAccessMethod</string>
			<key>IDXIndexBigEndian</key>
			<false/>
			<key>IDXIndexDataFields</key>
			<dict>
				<key>IDXExternalDataFields</key>
				<array>
					<dict>
						<key>IDXDataFieldName</key>
						<string>DCSExternalBodyID</string>
						<key>IDXDataSize</key>
						<integer>$body_id_size</integer>
						<key>IDXIndexName</key>
						<string>DCSBodyDataIndex</string>
					</dict>
				</array>
			</dict>
			<key>IDXIndexDataSizeLength</key>
			<integer>2</integer>
			<key>IDXIndexKeyMatchingMethods</key>
			<array>
				<string>IDXExactMatch</string>
			</array>
			<key>IDXIndexName</key>
			<string>DCSReferenceIndex</string>
			<key>IDXIndexPath</key>
			<string>EntryID.index</string>
			<key>IDXIndexSupportDataID</key>
			<false/>
			<key>IDXIndexWritable</key>
			<true/>
			<key>TrieAuxiliaryDataOptions</key>
			<dict>
				<key>IDXIndexPath</key>
				<string>EntryID.data</string>
			</dict>
END_OF_FILE

if [ $burst_trie -gt 0 ]
then
cat << END_OF_FILE
			<key>TrieIndexCompressionType</key>
			<integer>1</integer>
END_OF_FILE
fi

cat << END_OF_FILE
		</dict>
		<dict>
			<key>IDXIndexAccessMethod</key>
			<string>com.apple.HeapAccessMethod</string>
			<key>IDXIndexBigEndian</key>
			<false/>
			<key>IDXIndexDataFields</key>
			<dict>
				<key>IDXVariableDataFields</key>
				<array>
					<dict>
						<key>IDXDataFieldName</key>
						<string>DCSBodyData</string>
						<key>IDXDataSizeLength</key>
						<integer>4</integer>
					</dict>
				</array>
			</dict>
			<key>IDXIndexName</key>
			<string>DCSBodyDataIndex</string>
END_OF_FILE

if [ $compress_body -gt 0 ]
then
cat << END_OF_FILE
			<key>HeapDataCompressionType</key>
			<integer>$compress_body</integer>
END_OF_FILE
fi

if [ $encrypt_body -gt 0 ]
then
cat << END_OF_FILE
			<key>HeapDataEncrypted</key>
			<true/>
END_OF_FILE
fi

cat << END_OF_FILE
			<key>IDXIndexPath</key>
			<string>Body.data</string>
			<key>IDXIndexSupportDataID</key>
			<true/>
			<key>IDXIndexWritable</key>
			<true/>
		</dict>
	</array>
	<key>IDXDictionaryVersion</key>
	<integer>$dictionary_vers</integer>
	<key>DCSBuildToolVersion</key>
	<integer>$tool_vers</integer>
</dict>
</plist>
END_OF_FILE
