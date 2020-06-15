#!/bin/zsh
set -e

USER="dzhiblavi"
MODES=()
DIRS=()
FILES=()

declare -A CLRS
CLRS["Default"]=39
CLRS["Black"]=30 
CLRS["Red"]=31 
CLRS["Green"]=32
CLRS["Yellow"]=33
CLRS["Blue"]=34
CLRS["White"]=97

function coloured() {
    text=$1
    colour=$2
    pref="\e[1;${CLRS["$colour"]}m"
    suff="\e[0m"
    _return="$pref$text$suff"
}

function echoerr() { echo "$@" 1>&2; }

function colouredEcho() {
    text=$1
    colour=$2
    coloured $1 $2
    echoerr $_return
}

function reindent() {
vim -c "normal gg=G" $1 << 'EOF' 2> /dev/null
:wq
EOF
}

function walk() {
    odir=$dir
	consumer="$1"
	dir="$2"
	fileRegExp="$3"

    for item in $(ls ./$dir/); do
		if [[ -d "$dir$item" ]]; then
			walk "$consumer" "./$dir$item/" "$fileRegExp"
		elif [[ -f "$dir$item" ]] && [[ $item =~ $fileRegExp ]]; then
			$consumer "$dir$item"
		fi
	done
    dir=$odir
}

function showNotesConsumer() {
	FILE=$1
    REG="^%:: NOTE (.*)"

    colouredEcho "$FILE" "Red"

	OFS=$IFS
	IFS=$'\n'
	lineI=1
	for line in $(cat "$FILE"); do
		if [[ $line =~ $REG ]]; then
            coloured "$lineI" "Blue"
			echo "$_return:\t$match[1]"
		fi
		lineI=$(( lineI + 1 ))
	done
	IFS=$OFS
}

function gitAddConsumer() {
	FILE=$1
	echo "Adding file to git: $FILE"
	git add $FILE
}

function processDirsFiles() {
	pconsumer="$1"
	fileE=$2
	for dir in "${DIRS[@]}"; do
		walk "$pconsumer" "$dir" "$fileE"
	done
	for file in "${FILES[@]}"; do
		"$pconsumer" "$file"
	done	
}

function showNotes() {
	processDirsFiles showNotesConsumer ".*\.tex$"
}

function gitAdd() {
	processDirsFiles gitAddConsumer ".*\.tex$|.*\.pdf$"
	git add preamble.sty
    git add tickets.pdf
}

function reIndent() {
    processDirsFiles reindent ".*\.tex$"
}

function process() {
	MODE="$1"

	case "$MODE" in
		notes) {
			showNotes
		} ;;

		add) {
			gitAdd
		} ;;

        reindent) {
            reIndent
        } ;;

		*) {
			echo "Invalid mode: $MODE"
		} ;;
	esac
}


while [[ -n "$1" ]]; do
	case "$1" in
		-user) {
			shift
			USER="$1"
		} ;;

		-notes) {
			MODES+=("notes")
		} ;;

		-add) {
			MODES+=("add")
		} ;;

        -reindent) {
            MODES+=("reindent")
        } ;;

		-dir) {
			shift
			DIRS+=("$1")
		} ;; 

		-file) {
			shift
			FILES+=("$1")
		} ;;
	esac
	shift
done	


echo "Running: User = $USER"
for mode in "${MODES[@]}"; do
	echo "Processing mode: $mode"
	process "$mode"
done

