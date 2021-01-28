test_2seq() {
  do_test "2seq"
}

test_3seqZeropad() {
  do_test "3seqZeropad"
}

test_4seq() {
  do_test "4seq"
}

test_complex() {
  do_test "complex"
}

test_build() {
  do_test "build"
}

test_semver() {
  do_test "semver"
}

test_zoom() {
  do_test "zoom"
}

do_test() {
  local name="$1"
  local versionString=`head -1 ./testdata/${name}.version`

  genpattern=$(./make_ge_version_regex.sh -s -n $versionString | tail -2 | head -1)

  local lineno=0
  while read v; do
    lineno=$(($lineno+1))
    if [[ -z "$v" || "$v" =~ ^\# ]]; then continue; fi
    do_pos_test "$v" "$genpattern"
  done < testdata/${name}.positives

  lineno=0
  while read v; do
    lineno=$(($lineno+1))
    if [[ -z "$v" || "$v" =~ ^\# ]]; then continue; fi
    do_neg_test "$lineno" "$v" "$genpattern"
  done < testdata/${name}.negatives
}

do_pos_test() {
  local lineno="$1"
  local v="$2"
  local pattern="$3"

  exec_pattern "$v" "$pattern"
  if [[ $? == 0 ]]; then
    assert true "positives:${lineno}: version $v matched as expected"
  else
    assert false "positives:${lineno}: version $v failed to match: $pattern"
  fi
}

do_neg_test() {
  local lineno="$1"
  local v="$2"
  local pattern="$3"

  exec_pattern "$v" "$pattern"
  if [[ $? == 0 ]]; then
    assert false "negatives:${lineno}: expression $v matched unexpectedly: $pattern"
  else
    assert true "negatives:${lineno}: expression $v not matched as expected"
  fi
}

exec_pattern() {
  LC_ALL=C perl -e "q/$v/ =~ m/$pattern/ ? exit(0) : exit(1)"
}
