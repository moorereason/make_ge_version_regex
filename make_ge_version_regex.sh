#!/bin/bash

<<ABOUT_THIS_SCRIPT
-------------------------------------------------------------------------------

	Written by:William Smith
	Professional Services Engineer
	Jamf
	bill@talkingmoose.net
	https://gist.github.com/2cf20236e665fcd7ec41311d50c89c0e

	Originally posted: April 12, 2020

	Modified: May 6, 2020
	Changes:
	Adding support to break long regex strings for Jamf Pro.

	Modified: May 24, 2020
	Changes:
	Displaying sequence characters in verbose reporting instead of number.
	Now accounting for version strings with non-numeric characters.
	Added warning if sequence begins with "0".
	Added warning if sequence contains non-standard characters.
	Accounting for multple Jamf Pro regex strings.

  Modified: May 24, 2020 by Cameron Moore (github.com/moorereason)
	Changes:
	Simplify regex to produce 14-25% fewer characters.
	Add cli options to control verbose and usingJamf.
	Added unit tests to my fork.

	Purpose: Generate a regular expression (regex) string that matches
	the provided version number or higher.

	Instructions: Run the script in Terminal, supplying a version number
	string as the first argument:

	e.g. '/path/to/Match Version Number or Higher.bash' 16.17

	Or run the script in Terminal without any argument to use the example
	version number string within the script.

	Optionally, set verbose to "On" or "Off".

	Except where otherwise noted, this work is licensed under
	http://creativecommons.org/licenses/by/4.0/

	"Perhaps it is the forgetting not the remembering that is the essence
	of what makes us human. To make sense of the world, we must filter it."

-------------------------------------------------------------------------------
ABOUT_THIS_SCRIPT

# ----- set verbosity and provide a version number string ---------------------

# turn on for step-by-step explanation while building the regex or off to provide only the regex
verbose="On" # "On" or "Off"
usingJamf="Yes" # "Yes" or "No"

function usage() {
  echo -e "USAGE:\n\t$0 [OPTIONS] VERSION\n\nOPTIONS:\n\t-h: show help\n\t-n: not using jamf\n\t-s: silent mode"
  exit 0
}

# process cli options
while getopts ":hns" opt; do
  case "$opt" in
    h) usage ;;
    n) usingJamf="No" ;;
    s) verbose="Off" ;;
    ?)
      echo "Invalid option -${OPTARG}"
      exit 1
      ;;
  esac
done
# shift past options in the arguments array
shift $((OPTIND - 1))

# from supplied argument in Terminal
versionString=$1

# confirm version string only contains numbers and periods or is blank
if [[ $versionString =~ [^[:digit:].] ]]; then
	warning="Yes"
fi

# sample version strings
if [[ "$versionString" = "" ]]; then
	# versionString="79.0.3945.117" # e.g. Google Chrome
	# versionString="16.17" # Microsoft Office 2019
	# versionString="74.0.1" # Mozilla Firefox
	# versionString="19.10.2.41" # Citrix Workspace
	# versionString="20.006.20034" # Adobe Acrobat Reader DC
	# versionString="19.021.20058" # Adobe Acrobat Pro DC
	# versionString="21.0.3" # Adobe Photoshop 2020
	# versionString="100.86.91" # Microsoft Defender
	# versionString="5.0.3 (24978.0517)" # Zoom.us
	versionString="5.0.3-24978.0517 (4323)" # just a long and complicated test string
fi

# ----- functions -------------------------------------------------------------

# enables or disables verbose mode
function logcomment() {

	if [[ "$verbose" = "On" ]]; then
		echo "$1"
	fi
}

# processes a digit within a sequence
function evaluateSequence()	{

	# ----- process the first digit in a sequence -----------------------------

	# prepend exact characters leading up to the current character under evaluation
	if [[ "$regex" != "" ]]; then
		regex="$regex|"
	fi

	# get the sequence ( e.g. "74" of "74.0.1" )
	sequence=$( /usr/bin/awk -F "." -v i=$aSequence '{ print $i }' <<< "$adjustedVersionString" )
	logcomment "Sequence $aSequence is \"$sequence\""

	# show warning if sequence begins with "0"
	if [[ "$sequence" =~ ^0.+ ]]; then
		warning="Yes"
	fi

	# get count of digits in the sequence ( e.g. 2 digits in "74" )
	digitCount=$( /usr/bin/tr -d '\r\n' <<< "$sequence" | /usr/bin/wc -c | /usr/bin/xargs ) # e.g. 2
	logcomment "Count of digits in sequence \"$sequence\" is $digitCount"
	logcomment

	# generate regex for the first number of the sequence rolling over to add another digit ( e.g. 99 > 100 )
	logcomment "Count of digits in sequence \"$sequence\" may roll over to $((digitCount + 1)) or more digits"
	buildRegex="$regexPrefix\d{$((digitCount + 1))}"
	logcomment "Regex for $((digitCount + 1)) or more digits is \"$buildRegex\""

	# show complete regex for this digit
	logcomment "Complete regex is \"$buildRegex\""
	regex="$regex$buildRegex"

	# show the entire regex as the script progresses through each digit
	logcomment "Progressive regex: $regex"
	logcomment

	# ----- process the remaining digits in a sequence ------------------------

	# create array of digits in sequence ( e.g. "7, 4" )
	digits=()
	for ((i = 0; i < ${#sequence}; i++)); do
		digits+=(${sequence:$i:1})
	done

	# iterate over each digit of the sequence
	# for aDigit in ${digits[*]}
	for indexNumber in "${!digits[@]}"
	do
		# ----- the number 8 can only roll up to 9 ----------------------------

		if [[ "${digits[$indexNumber]}" -eq 8 ]]; then
			logcomment "Because digit $((indexNumber + 1 )) in sequence \"$sequence\" is \"8\", roll it to \"9\""
			buildRegex="9"

			if [[ $((digitCount - indexNumber - 1 )) -ne 0 ]]; then
				logcomment "Because remaining count of digits in sequence \"$sequence\" is $((digitCount - indexNumber - 1 )), pad the sequence with $((digitCount - indexNumber - 1 )) more digit(s)"
				buildRegex="$buildRegex\d{$((digitCount - indexNumber - 1 ))}"
				logcomment "Regex for $((digitCount - indexNumber - 1 )) more digit(s) is \d{$((digitCount - indexNumber - 1 ))}"
			fi

			buildRegex="$regexPrefix$buildRegex"
			logcomment "Complete regex is \"$buildRegex\""

			logcomment "Progressive regex: $regex|$buildRegex"
			regex="$regex|$buildRegex"
			logcomment

		# ----- the number 7 can roll up to [89] ------------------------------

		elif [[ "${digits[$indexNumber]}" -eq 7 ]]; then
			logcomment "Because digit $((indexNumber + 1 )) in sequence \"$sequence\" is \"7\", roll it to \"[89]\""
			buildRegex="[89]"

			if [[ $((digitCount - indexNumber - 1 )) -ne 0 ]]; then
				logcomment "Because remaining count of digits in sequence \"$sequence\" is $((digitCount - indexNumber - 1 )), pad the sequence with $((digitCount - indexNumber - 1 )) more digit(s)"
				buildRegex="$buildRegex\d{$((digitCount - indexNumber - 1 ))}"
				logcomment "Regex for $((digitCount - indexNumber - 1 )) more digit(s) is \d{$((digitCount - indexNumber - 1 ))}"
			fi

			buildRegex="$regexPrefix$buildRegex"
			logcomment "Complete regex is \"$buildRegex\""

			logcomment "Progressive regex: $regex|$buildRegex"
			regex="$regex|$buildRegex"
			logcomment

		# ----- anything 0 through 6 will roll up to the next number ----------

		elif [[ "${digits[$indexNumber]}" -lt 7 ]]; then
			logcomment "Because digit $((indexNumber + 1 )) in sequence \"$sequence\" is \"${digits[$indexNumber]}\", roll it to \"$((${digits[$indexNumber]} + 1))\" or higher"
			buildRegex="[$((${digits[$indexNumber]} + 1))-9]"
			logcomment "Regex for $((${digits[$indexNumber]} + 1)) or higher is \"$buildRegex\""

			if [[ $((digitCount - indexNumber - 1 )) -ne 0 ]]; then
				logcomment "Because remaining count of digits in sequence \"$sequence\" is $((digitCount - indexNumber - 1 )), pad the sequence with $((digitCount - indexNumber - 1 )) more digit(s)"
				buildRegex="$buildRegex\d{$((digitCount - indexNumber - 1 ))}"
				logcomment "Regex for $((digitCount - indexNumber - 1 )) more digit(s) is \d{$((digitCount - indexNumber - 1 ))}"
			fi

			buildRegex="$regexPrefix$buildRegex"
			logcomment "Complete regex is \"$buildRegex\""

			logcomment "Progressive regex: $regex|$buildRegex"
			regex="$regex|$buildRegex"
			logcomment

		# ----- nothing to do if the digit is 9 -------------------------------
		# ----- (the preceding digit is already rolled up) --------------------

		else
			logcomment "Because \"Digit $((indexNumber + 1 ))\" in sequence \"$sequence\" is 9, do nothing"
			logcomment
		fi

		regexPrefix="$regexPrefix${digits[$indexNumber]}"
	done
}

# processes a digit within a sequence
function evaluateSequenceOptimized()	{

	# ----- process the first digit in a sequence -----------------------------

	# if we've processed a previous sequence, begin a new group member with a new
	# nested grouping
	if [[ "$regex" != "" ]]; then
		regex="$regex|$regexPrefix("
	fi

	# get the sequence ( e.g. "74" of "74.0.1" )
	sequence=$( /usr/bin/awk -F "." -v i=$aSequence '{ print $i }' <<< "$adjustedVersionString" )
	logcomment "Sequence $aSequence is \"$sequence\""

	# show warning if sequence begins with "0"
	if [[ "$sequence" =~ ^0.+ ]]; then
		warning="Yes"
	fi

	# get count of digits in the sequence ( e.g. 2 digits in "74" )
	digitCount=$( /usr/bin/tr -d '\r\n' <<< "$sequence" | /usr/bin/wc -c | /usr/bin/xargs ) # e.g. 2
	logcomment "Count of digits in sequence \"$sequence\" is $digitCount"
	logcomment

	# generate regex for the first number of the sequence rolling over to add another digit ( e.g. 99 > 100 )
	logcomment "Count of digits in sequence \"$sequence\" may roll over to $((digitCount + 1)) or more digits"
	buildRegex="\d{$((digitCount + 1))}"
	logcomment "Regex for $((digitCount + 1)) or more digits is \"$buildRegex\""

	# show complete regex for this digit
	logcomment "Complete regex is \"$buildRegex\""
	regex="$regex$buildRegex"

	# show the entire regex as the script progresses through each digit
	logcomment "Progressive regex: $regex"
	logcomment

	# ----- process the remaining digits in a sequence ------------------------

	# create array of digits in sequence ( e.g. "7, 4" )
	digits=()
	for ((i = 0; i < ${#sequence}; i++)); do
		digits+=(${sequence:$i:1})
	done

	segmentPrefix=""

	# iterate over each digit of the sequence
	# for aDigit in ${digits[*]}
	for indexNumber in "${!digits[@]}"
	do
		# ----- the number 8 can only roll up to 9 ----------------------------

		if [[ "${digits[$indexNumber]}" -eq 8 ]]; then
			logcomment "Because digit $((indexNumber + 1 )) in sequence \"$sequence\" is \"8\", roll it to \"9\""
			buildRegex="9"

			if [[ $((digitCount - indexNumber - 1 )) -ne 0 ]]; then
				logcomment "Because remaining count of digits in sequence \"$sequence\" is $((digitCount - indexNumber - 1 )), pad the sequence with $((digitCount - indexNumber - 1 )) more digit(s)"
				buildRegex="$buildRegex\d{$((digitCount - indexNumber - 1 ))}"
				logcomment "Regex for $((digitCount - indexNumber - 1 )) more digit(s) is \d{$((digitCount - indexNumber - 1 ))}"
			fi

			buildRegex="$segmentPrefix$buildRegex"
			logcomment "Complete regex is \"$buildRegex\""

			regex="$regex|$buildRegex"
			logcomment "Progressive regex: $regex"

		# ----- the number 7 can roll up to [89] ------------------------------

		elif [[ "${digits[$indexNumber]}" -eq 7 ]]; then
			logcomment "Because digit $((indexNumber + 1 )) in sequence \"$sequence\" is \"7\", roll it to \"[89]\""
			buildRegex="[89]"

			if [[ $((digitCount - indexNumber - 1 )) -ne 0 ]]; then
				logcomment "Because remaining count of digits in sequence \"$sequence\" is $((digitCount - indexNumber - 1 )), pad the sequence with $((digitCount - indexNumber - 1 )) more digit(s)"
				buildRegex="$buildRegex\d{$((digitCount - indexNumber - 1 ))}"
				logcomment "Regex for $((digitCount - indexNumber - 1 )) more digit(s) is \d{$((digitCount - indexNumber - 1 ))}"
			fi

			buildRegex="$segmentPrefix$buildRegex"
			logcomment "Complete regex is \"$buildRegex\""

			regex="$regex|$buildRegex"
			logcomment "Progressive regex: $regex"

		# ----- anything 0 through 6 will roll up to the next number ----------

		elif [[ "${digits[$indexNumber]}" -lt 7 ]]; then
			logcomment "Because digit $((indexNumber + 1 )) in sequence \"$sequence\" is \"${digits[$indexNumber]}\", roll it to \"$((${digits[$indexNumber]} + 1))\" or higher"
			buildRegex="[$((${digits[$indexNumber]} + 1))-9]"
			logcomment "Regex for $((${digits[$indexNumber]} + 1)) or higher is \"$buildRegex\""

			if [[ $((digitCount - indexNumber - 1 )) -ne 0 ]]; then
				logcomment "Because remaining count of digits in sequence \"$sequence\" is $((digitCount - indexNumber - 1 )), pad the sequence with $((digitCount - indexNumber - 1 )) more digit(s)"
				buildRegex="$buildRegex\d{$((digitCount - indexNumber - 1 ))}"
				logcomment "Regex for $((digitCount - indexNumber - 1 )) more digit(s) is \d{$((digitCount - indexNumber - 1 ))}"
			fi

			buildRegex="$segmentPrefix$buildRegex"
			logcomment "Complete regex is \"$buildRegex\""

			regex="$regex|$buildRegex"
			logcomment "Progressive regex: $regex"

		# ----- nothing to do if the digit is 9 -------------------------------
		# ----- (the preceding digit is already rolled up) --------------------

		else
			logcomment "Because \"Digit $((indexNumber + 1 ))\" in sequence \"$sequence\" is 9, do nothing"
		fi

		regexPrefix="$sequence"

		segmentPrefix=$( /usr/bin/tr -d ' ' <<< "${digits[@]:0:$(($indexNumber+1))}" )
		logcomment "Save segment prefix \"$segmentPrefix\""
		logcomment
	done
}

# ----- run the script --------------------------------------------------------

function generatePattern() {
  regex=""

  # used to track unchanged digits to the left of the current digit being evaluated
  regexPrefix=""

  # evaluate the version string
  for ((aSequence=1;aSequence<=$sequenceCount;aSequence++))
  do
    logcomment "Evaluating sequence $aSequence of $sequenceCount"
    if [[ "$fallback" -eq 0 ]]; then
      evaluateSequenceOptimized
    else
      evaluateSequence
    fi

    # resetting variable
    dividers=""

    # add sequence divider to end of the sequence
    divider=$( /usr/bin/awk -F "###" -v divider=$(( aSequence + 1 )) '{ print $divider }' <<< "$sequenceDividers" )

    for (( aCharacter=0; aCharacter<${#divider}; aCharacter++ ))
    do
      logcomment "Next character is \"${divider:$aCharacter:1}\""

      if [[ "$regexSpecialCharacters" = *"${divider:$aCharacter:1}"* ]]; then
        dividers="$dividers\\${divider:$aCharacter:1}"
        logcomment "Escaping \"${divider:$aCharacter:1}\" to create \"\\${divider:$aCharacter:1}\""

      else
        dividers="$dividers${divider:$aCharacter:1}"
        logcomment "This character does not need escaping"
      fi
    done
    regexPrefix="$regexPrefix$dividers"
  done

  regex="$regex|$regexPrefix"

  if [[ "$fallback" -eq 0 ]]; then
    # Close off all nested groups (excluding the main outer group)
    for ((aSequence=1;aSequence<$sequenceCount;aSequence++))
    do
      regex="$regex)"
    done
  fi

  logcomment "Progressive regex: $regex"
  logcomment

  # return full regex including start and end of string characters (e.g. ^ and $ )
  regex="^($regex)"
}

# ----- run the script --------------------------------------------------------

# fallback is 1 when using the non-grouping pattern generator for jamf
fallback=0

# verify the version string to the user
logcomment "Version string is $versionString"

# replace non-numeric sequences of characters with periods
adjustedVersionString=$( /usr/bin/sed -E 's/[^0-9]+/./g' <<< "$versionString" | /usr/bin/sed -E 's/[^0-9]$//g' )
logcomment "Adjusted version string for parsing is \"$adjustedVersionString\""

# number of "sequences" separated by a divider
sequenceCount=$( /usr/bin/awk -F "." '{ print NF }' <<< "$adjustedVersionString" ) # e.g. 4
logcomment "Number of sequences is $sequenceCount"

# create a list of sequence dividers in the version string separated by "###"
sequenceDividers=$( /usr/bin/sed -E 's/[0-9]+/###/g' <<< "$versionString" )
logcomment "Replacing digits in sequences to get the sequence dividers \"$sequenceDividers\""
logcomment

# 14 special regex characters that may appear as sequence dividers that will need escaping
regexSpecialCharacters="\&$.|?*+()[]{}"

# Generate the optimized pattern (fallback=0)
generatePattern

if [[ "$usingJamf" = "Yes" ]] && [[ "$fallback" -eq 0 ]] && [[ "${#regex}" -gt 255 ]]; then
  logcomment "!!!"
  logcomment "!!! Optimized pattern too long for jamf ($((${#regex})) > 255)"
  logcomment "!!!"
  logcomment "!!! Rebuilding with non-grouping pattern generator..."
  logcomment "!!!"
  logcomment

  fallback=1
  generatePattern
fi

if [[ "$warning" = "Yes" ]]; then
	echo
	echo "==============================================="
	echo "                                               "
	echo "                    WARNING                    "
	echo "                                               "
	echo "   This version string contains non-standard   "
	echo "   characters or number sequences that begin   "
	echo "   with a zero (i.e. \"0123\", which is the    "
	echo "   same as \"123\").                           "
	echo "                                               "
	echo "   Use regexes with caution.                   "
	echo "                                               "
	echo "==============================================="
	echo
fi

# get characterCount of regex
regexCharacterCount=$( /usr/bin/wc -c <<< "$regex" | /usr/bin/xargs )

# display the regex for the version string and its character count
echo
echo "Regex for \"$versionString\" or higher ($regexCharacterCount characters):

$regex"
echo

if [[ "$usingJamf" = "Yes" ]] && [[ "$regexCharacterCount" -gt 255 ]]; then

	# get count of characters in generated regex string
	regexCharacters=${#regex}

	# determine number of regex strings needed, accounting for beginning ^ and ending $ characters
	jamfStringCount="$((regexCharacters / 254 + 1))"

	# get number of sequences separated by | in regex
	sequenceCount=$( /usr/bin/awk -F "|" '{ print NF }' <<< "$regex" )

	# divide the count of sequences in half
	breakDelimiterPosition=$((sequenceCount / jamfStringCount))

	# replace middle | operator(s) with the letter "b"
	dividedRegex="$regex"

	for (( aBreak=0; aBreak<$jamfStringCount; aBreak++ ))
	do
		breakDelimiterPosition=$((breakDelimiterPosition * aBreak + breakDelimiterPosition))
		dividedRegex=$( /usr/bin/sed "s/|/±/$breakDelimiterPosition" <<< "$dividedRegex" )
	done

	# print Jamf Pro instructions and both regex strings
	echo
	echo "Jamf Pro has a field character limit of 255 characters."
	echo "This regex exceeds that field character limit."
	echo "Add additional \"Application Version\" criteria to your search"
	echo "and paste each regex string into the the additional fields."
	echo
	echo
	echo "For example:"
	echo
	echo "              Application Title       is                Google Chrome.app"
	echo "and     (     Application Version     matches regex     <Regex 1>"
	echo "or            Application Version     matches regex     <Regex 2>     )"
	echo
	echo

	# display each Jamf Pro string
	for (( aBreak=0; aBreak<$jamfStringCount; aBreak++ ))
	do
		regexString=$( /usr/bin/awk -F "±" -v divider=$(( aBreak + 1 )) '{ print $divider }' <<< "$dividedRegex" )

		# add beginning of line characters if needed
		if [[ "$regexString" != "^("* ]]; then
			regexString="^($regexString"
		fi

		# add end of line characters if needed
		if [[ "$regexString" != *")$" ]]; then
			regexString="$regexString)$"
		fi

		# display each regex string
		echo "Regex $((aBreak + 1)):"
		echo "$regexString"
		echo
	done
fi

exit 0
