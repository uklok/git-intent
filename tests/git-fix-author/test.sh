#!/usr/bin/env bash
set -euo pipefail

repository_root=$(git rev-parse --show-toplevel)
tool=$repository_root/skills/git-fix-author/scripts/git-fix-author
test_root=$(mktemp -d "${TMPDIR:-/tmp}/git-fix-author-tests.XXXXXX")
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

passed=0
failed=0
test_index=0

pass() {
  passed=$((passed + 1))
  printf 'ok %s - %s\n' "$test_index" "$1"
}

fail_test() {
  failed=$((failed + 1))
  printf 'not ok %s - %s\n' "$test_index" "$1" >&2
}

assert_eq() {
  actual=$1
  expected=$2
  message=$3
  if [[ $actual != "$expected" ]]; then
    printf 'assertion failed: %s\nexpected: %s\nactual:   %s\n' \
      "$message" "$expected" "$actual" >&2
    return 1
  fi
}

assert_contains() {
  value=$1
  expected=$2
  message=$3
  if [[ $value != *"$expected"* ]]; then
    printf 'assertion failed: %s\nmissing: %s\noutput:\n%s\n' \
      "$message" "$expected" "$value" >&2
    return 1
  fi
}

new_repo() {
  repo=$1
  mkdir -p "$repo"
  git -C "$repo" init -q -b main 2>/dev/null || {
    git -C "$repo" init -q
    git -C "$repo" checkout -q -b main
  }
  git -C "$repo" config user.name 'Configured User'
  git -C "$repo" config user.email configured@example.com
  git -C "$repo" config commit.gpgSign false
}

commit_file() {
  repo=$1
  path=$2
  content=$3
  message=$4
  timestamp=$5
  printf '%s\n' "$content" >"$repo/$path"
  git -C "$repo" add "$path"
  GIT_AUTHOR_DATE=$timestamp GIT_COMMITTER_DATE=$timestamp \
    git -C "$repo" commit -q -m "$message"
}

backup_count() {
  git for-each-ref --format='%(refname)' refs/backup/ | wc -l | tr -d ' '
}

extract_commit_message() {
  git -C "$1" cat-file commit "$2" |
    {
      while IFS= read -r header_line; do
        [[ -n $header_line ]] || break
      done
      cat
    }
}

run_test() {
  name=$1
  shift
  test_index=$((test_index + 1))
  set +e
  (
    set -e
    "$@"
  )
  test_status=$?
  set -e
  if [[ $test_status -eq 0 ]]; then
    pass "$name"
  else
    fail_test "$name"
  fi
}

test_help() {
  output=$($tool --help)
  assert_contains "$output" 'Usage:' 'help shows usage'
  assert_contains "$output" '--non-interactive' 'help documents automation'
  assert_contains "$output" '--no-update-refs' 'help documents ref scope'
}

test_linear_rewrite_and_backup() {
  repo=$test_root/linear
  new_repo "$repo"
  commit_file "$repo" story.txt one 'root message' '2025-01-01T10:00:00-04:00'
  start_oid=$(git -C "$repo" rev-parse HEAD)
  commit_file "$repo" story.txt two $'subject\n\nbody' '2025-02-02T11:30:00-04:00'
  GIT_AUTHOR_DATE='2025-03-03T12:45:00-04:00' \
    GIT_COMMITTER_DATE='2025-03-03T12:45:00-04:00' \
    git -C "$repo" commit -q --allow-empty -m 'empty marker'
  old_tip=$(git -C "$repo" rev-parse HEAD)
  old_trees=$(git -C "$repo" log --reverse --format=%T "$old_tip")
  old_messages=$(git -C "$repo" log --reverse --format='---%n%B' "$old_tip")
  old_author_dates=$(git -C "$repo" log --reverse --format=%aI "$old_tip")
  old_committer_dates=$(git -C "$repo" log --reverse --format=%cI "$old_tip")
  configured_name=$(git -C "$repo" config user.name)
  configured_email=$(git -C "$repo" config user.email)
  isolated_home=$test_root/linear-home
  mkdir -p "$isolated_home"
  HOME=$isolated_home git config --global user.name 'Global User'
  HOME=$isolated_home git config --global user.email global@example.com

  output=$(cd "$repo" && HOME=$isolated_home "$tool" --start "$start_oid" --name 'Correct Author' \
    --email correct@example.com --non-interactive --yes)

  new_tip=$(git -C "$repo" rev-parse HEAD)
  [[ $new_tip != "$old_tip" ]]
  assert_eq "$(git -C "$repo" log --reverse --format=%T HEAD)" "$old_trees" 'trees survive'
  assert_eq "$(git -C "$repo" log --reverse --format='---%n%B' HEAD)" "$old_messages" 'messages survive'
  assert_eq "$(git -C "$repo" log --reverse --format=%aI HEAD)" "$old_author_dates" 'author dates survive'
  assert_eq "$(git -C "$repo" log --reverse --format=%cI HEAD)" "$old_committer_dates" 'committer dates survive'
  assert_eq "$(git -C "$repo" log --format='%an <%ae>|%cn <%ce>' | sort -u)" \
    'Correct Author <correct@example.com>|Correct Author <correct@example.com>' 'identities applied'
  assert_eq "$(git -C "$repo" config user.name)" "$configured_name" 'configured name unchanged'
  assert_eq "$(git -C "$repo" config user.email)" "$configured_email" 'configured email unchanged'
  assert_eq "$(HOME=$isolated_home git config --global user.name)" 'Global User' 'global name unchanged'
  assert_eq "$(HOME=$isolated_home git config --global user.email)" \
    'global@example.com' 'global email unchanged'
  assert_eq "$(cd "$repo" && backup_count)" '1' 'one backup exists'
  backup_ref=$(git -C "$repo" for-each-ref --format='%(refname)' refs/backup/)
  assert_eq "$(git -C "$repo" rev-parse "$backup_ref")" "$old_tip" 'backup reaches old tip'
  assert_contains "$output" '[ok] 3 commits rewritten' 'verification summary reported'
}

test_dry_run_is_pure() {
  repo=$test_root/dry-run
  new_repo "$repo"
  commit_file "$repo" file.txt one root '2025-01-01T10:00:00Z'
  start_oid=$(git -C "$repo" rev-parse HEAD)
  commit_file "$repo" file.txt two second '2025-01-02T10:00:00Z'
  old_tip=$(git -C "$repo" rev-parse HEAD)
  old_objects=$(git -C "$repo" count-objects -v)

  output=$(cd "$repo" && "$tool" --start "$start_oid" --name Preview \
    --email preview@example.com --dry-run --non-interactive)

  assert_eq "$(git -C "$repo" rev-parse HEAD)" "$old_tip" 'dry run keeps tip'
  assert_eq "$(cd "$repo" && backup_count)" '0' 'dry run creates no backup'
  assert_eq "$(git -C "$repo" count-objects -v)" "$old_objects" 'dry run writes no objects'
  assert_contains "$output" 'Dry run only; nothing changed.' 'dry run result is explicit'
}

test_raw_message_bytes_survive() {
  repo=$test_root/raw-message
  new_repo "$repo"
  tree_oid=$(git -C "$repo" mktree </dev/null)
  old_oid=$(
    printf 'message without final newline' |
      GIT_AUTHOR_DATE='2025-01-01T10:00:00Z' \
        GIT_COMMITTER_DATE='2025-01-01T10:00:00Z' \
        git -C "$repo" commit-tree "$tree_oid"
  )
  git -C "$repo" update-ref refs/heads/main "$old_oid"
  extract_commit_message "$repo" "$old_oid" >"$test_root/old-raw-message"

  (cd "$repo" && "$tool" --start "$old_oid" --name Author \
    --email author@example.com --non-interactive --yes >/dev/null)

  new_oid=$(git -C "$repo" rev-parse main)
  extract_commit_message "$repo" "$new_oid" >"$test_root/new-raw-message"
  cmp -s "$test_root/old-raw-message" "$test_root/new-raw-message"
  assert_eq "$(wc -c <"$test_root/new-raw-message" | tr -d ' ')" '29' \
    'message byte length is exact'
}

test_explicit_committer_and_no_backup() {
  repo=$test_root/committer
  new_repo "$repo"
  commit_file "$repo" file.txt one root '2025-01-01T10:00:00Z'
  start_oid=$(git -C "$repo" rev-parse HEAD)

  (cd "$repo" && "$tool" --start "$start_oid" --name Author \
    --email author@example.com --committer-name Operator \
    --committer-email operator@example.com --no-backup \
    --non-interactive --yes >/dev/null)

  assert_eq "$(git -C "$repo" show -s --format='%an <%ae>')" \
    'Author <author@example.com>' 'explicit author applied'
  assert_eq "$(git -C "$repo" show -s --format='%cn <%ce>')" \
    'Operator <operator@example.com>' 'explicit committer applied'
  assert_eq "$(cd "$repo" && backup_count)" '0' 'no-backup is honored'
}

test_merge_topology_and_update_refs() {
  repo=$test_root/merge
  new_repo "$repo"
  commit_file "$repo" base.txt base base '2025-01-01T10:00:00Z'
  git -C "$repo" checkout -q -b side
  commit_file "$repo" side.txt side side '2025-01-02T10:00:00Z'
  side_tip=$(git -C "$repo" rev-parse HEAD)
  git -C "$repo" checkout -q main
  commit_file "$repo" main.txt main start '2025-01-03T10:00:00Z'
  start_oid=$(git -C "$repo" rev-parse HEAD)
  GIT_AUTHOR_DATE='2025-01-04T10:00:00Z' GIT_COMMITTER_DATE='2025-01-04T10:00:00Z' \
    git -C "$repo" merge -q --no-ff side -m merge
  old_tip=$(git -C "$repo" rev-parse HEAD)
  old_parent_count=$(git -C "$repo" show -s --format=%P HEAD | wc -w | tr -d ' ')

  (cd "$repo" && "$tool" --start "$start_oid" --name Unified \
    --email unified@example.com --non-interactive --yes >/dev/null)

  new_tip=$(git -C "$repo" rev-parse main)
  [[ $new_tip != "$old_tip" ]]
  assert_eq "$(git -C "$repo" show -s --format=%P main | wc -w | tr -d ' ')" \
    "$old_parent_count" 'merge parent count survives'
  [[ $(git -C "$repo" rev-parse side) != "$side_tip" ]]
  assert_eq "$(git -C "$repo" show -s --format='%an <%ae>' side)" \
    'Unified <unified@example.com>' 'related local branch moves'

  merge_output=$test_root/merge-start-output
  if (cd "$repo" && "$tool" --start main --name Again --email again@example.com \
    --dry-run --non-interactive >"$merge_output" 2>&1); then
    return 1
  fi
  assert_contains "$(<"$merge_output")" 'start commit is a merge' \
    'ambiguous merge boundary is rejected'
}

test_no_update_refs() {
  repo=$test_root/no-update-refs
  new_repo "$repo"
  commit_file "$repo" file.txt one root '2025-01-01T10:00:00Z'
  start_oid=$(git -C "$repo" rev-parse HEAD)
  git -C "$repo" branch marker
  marker_oid=$(git -C "$repo" rev-parse marker)
  commit_file "$repo" file.txt two second '2025-01-02T10:00:00Z'

  (cd "$repo" && "$tool" --start "$start_oid" --name Author \
    --email author@example.com --no-update-refs --non-interactive --yes >/dev/null)

  assert_eq "$(git -C "$repo" rev-parse marker)" "$marker_oid" 'marker branch stays put'
  [[ $(git -C "$repo" rev-parse main) != "$marker_oid" ]]
}

test_bounded_range_on_another_branch() {
  repo=$test_root/bounded
  new_repo "$repo"
  commit_file "$repo" file.txt base base '2025-01-01T10:00:00Z'
  base_oid=$(git -C "$repo" rev-parse HEAD)
  git -C "$repo" checkout -q -b feature
  commit_file "$repo" file.txt feature feature '2025-01-02T10:00:00Z'
  feature_oid=$(git -C "$repo" rev-parse HEAD)
  git -C "$repo" tag retained-tag
  git -C "$repo" checkout -q main
  main_before=$(git -C "$repo" rev-parse main)
  worktree_before=$(git -C "$repo" status --porcelain=v1)

  (cd "$repo" && "$tool" --start "$feature_oid" --finish feature \
    --name Feature --email feature@example.com --non-interactive --yes >/dev/null)

  assert_eq "$(git -C "$repo" symbolic-ref --short HEAD)" 'main' 'current branch does not change'
  assert_eq "$(git -C "$repo" rev-parse main)" "$main_before" 'unrelated current branch does not move'
  assert_eq "$(git -C "$repo" status --porcelain=v1)" "$worktree_before" 'working tree does not change'
  assert_eq "$(git -C "$repo" show -s --format='%an <%ae>' feature)" \
    'Feature <feature@example.com>' 'bounded commit is rewritten'
  assert_eq "$(git -C "$repo" show -s --format='%an <%ae>' "$base_oid")" \
    'Configured User <configured@example.com>' 'boundary parent is untouched'
  assert_eq "$(git -C "$repo" rev-parse retained-tag)" "$feature_oid" 'tags are untouched'
}

test_nonancestor_is_rejected() {
  repo=$test_root/nonancestor
  new_repo "$repo"
  commit_file "$repo" file.txt base base '2025-01-01T10:00:00Z'
  git -C "$repo" checkout -q -b unrelated
  commit_file "$repo" unrelated.txt unrelated unrelated '2025-01-02T10:00:00Z'
  unrelated_oid=$(git -C "$repo" rev-parse HEAD)
  git -C "$repo" checkout -q main
  commit_file "$repo" main.txt main main '2025-01-03T10:00:00Z'
  main_before=$(git -C "$repo" rev-parse main)

  output_file=$test_root/nonancestor-output
  if (cd "$repo" && "$tool" --start "$unrelated_oid" --finish main \
    --name Author --email author@example.com --dry-run \
    --non-interactive >"$output_file" 2>&1); then
    return 1
  fi
  output=$(<"$output_file")
  assert_contains "$output" 'is not an ancestor' 'ancestry error is specific'
  assert_eq "$(git -C "$repo" rev-parse main)" "$main_before" 'rejection keeps finish ref'
  assert_eq "$(cd "$repo" && backup_count)" '0' 'rejection creates no backup'
}

test_rejections() {
  repo=$test_root/rejections
  new_repo "$repo"
  commit_file "$repo" file.txt one root '2025-01-01T10:00:00Z'
  start_oid=$(git -C "$repo" rev-parse HEAD)
  commit_file "$repo" file.txt two second '2025-01-02T10:00:00Z'

  printf 'dirty\n' >"$repo/untracked.txt"
  if (cd "$repo" && "$tool" --start "$start_oid" --name Author \
    --email author@example.com --non-interactive --yes >/dev/null 2>&1); then
    return 1
  fi
  rm "$repo/untracked.txt"

  if (cd "$repo" && "$tool" --start missing --name Author \
    --email author@example.com --dry-run --non-interactive >/dev/null 2>&1); then
    return 1
  fi

  if (cd "$repo" && "$tool" --start "$start_oid" --name Author \
    --email author@example.com --non-interactive >/dev/null 2>&1); then
    return 1
  fi

  assert_eq "$(cd "$repo" && backup_count)" '0' 'rejections create no backup'
}

printf 'TAP version 13\n'
run_test 'help documents the public interface' test_help
run_test 'linear rewrite verifies history and creates recovery' test_linear_rewrite_and_backup
run_test 'dry run is read-only' test_dry_run_is_pure
run_test 'raw commit-message bytes survive exactly' test_raw_message_bytes_survive
run_test 'explicit committer and no-backup work' test_explicit_committer_and_no_backup
run_test 'merge topology and related local refs survive' test_merge_topology_and_update_refs
run_test 'no-update-refs limits ref mutation' test_no_update_refs
run_test 'bounded rewrite can target a non-current branch' test_bounded_range_on_another_branch
run_test 'non-ancestor ranges are rejected without mutation' test_nonancestor_is_rejected
run_test 'unsafe and incomplete requests are rejected' test_rejections

total=$((passed + failed))
printf '1..%s\n' "$total"
if [[ $failed -ne 0 ]]; then
  printf '%s test(s) failed\n' "$failed" >&2
  exit 1
fi
printf 'All %s tests passed.\n' "$passed"
