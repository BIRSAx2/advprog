#!/usr/bin/env bash
# Packages each week's exercises into standalone units and bundles them
# into a single zip under build/.
#
# "Standalone" means: each Flix week gets its own flix.toml and its
# top-level runner renamed to `main`, so `flix run` works inside that
# week's folder alone, with no other week's file present. week3.pl and
# week4.fut need no such rewriting since they already have no
# cross-week dependencies.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

src_dir="src"
build_dir="build"
zip_name="${1:-advprog-weeks.zip}"

week1_src="$src_dir/week1.flix"
week2_src="$src_dir/week2.flix"
week3_src="$src_dir/week3.pl"
week4_src="$src_dir/week4.fut"

for f in "$week1_src" "$week2_src" "$week3_src" "$week4_src"; do
    if [[ ! -f "$f" ]]; then
        echo "error: missing $f" >&2
        exit 1
    fi
done

flix_version="$(grep -E '^flix\s*=' flix.toml | sed -E 's/.*"([^"]+)".*/\1/')"

mkdir -p "$build_dir"

staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT

make_flix_week() {
    local week_name="$1" src_file="$2" run_fn="$3"
    local week_dir="$staging_dir/$week_name"
    mkdir -p "$week_dir"

    # Plain (non-word-boundary) substitution: portable across BSD/GNU sed,
    # and safe here since run_fn names (runWeek1, runWeek2) are not
    # substrings of any other identifier in these files.
    sed "s/${run_fn}/main/g" "$src_file" > "$week_dir/${week_name}.flix"

    cat > "$week_dir/flix.toml" <<EOF
[package]
name        = "$week_name"
description = ""
version     = "0.1.0"
flix        = "$flix_version"
authors     = ["Mouhieddine Sabir"]
EOF
}

make_flix_week "week1" "$week1_src" "runWeek1"
make_flix_week "week2" "$week2_src" "runWeek2"

mkdir -p "$staging_dir/week3"
cp "$week3_src" "$staging_dir/week3/week3.pl"

mkdir -p "$staging_dir/week4"
cp "$week4_src" "$staging_dir/week4/week4.fut"

zip_path="$build_dir/$zip_name"
rm -f "$zip_path"
(cd "$staging_dir" && zip -rq "$repo_root/$zip_path" week1 week2 week3 week4)

echo "Created $zip_path"
