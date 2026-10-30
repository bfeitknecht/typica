default:
    @just --list

# Run full compilation, XML/link verification, and Universe staging checks
check:
    #!/usr/bin/env sh
    set -eu
    tmp_pkg=".tmp-pkg"
    tmp_check=".tmp-check"
    tmp_stage=".tmp-stage"
    rm -rf "$tmp_pkg" "$tmp_check" "$tmp_stage"
    trap 'rm -rf "$tmp_pkg" "$tmp_check" "$tmp_stage"' EXIT

    pkg_name="$(sed -n 's/^name = "\(.*\)"/\1/p' typst.toml)"
    pkg_ver="$(sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)"
    mkdir -p "$tmp_pkg/preview/$pkg_name"
    ln -s "$(pwd)" "$tmp_pkg/preview/$pkg_name/$pkg_ver"

    for manifest in vendor/*/typst.toml; do
        [ -f "$manifest" ] || continue
        v_dir="$(cd "$(dirname "$manifest")" && pwd)"
        v_name="$(sed -n 's/^name = "\(.*\)"/\1/p' "$manifest")"
        v_ver="$(sed -n 's/^version = "\(.*\)"/\1/p' "$manifest")"
        mkdir -p "$tmp_pkg/preview/$v_name"
        ln -s "$v_dir" "$tmp_pkg/preview/$v_name/$v_ver"
    done

    mkdir -p "$tmp_check"

    # 1. Compile template & all examples as HTML bundles
    for site_dir in template examples/minimal examples/custom-theme examples/co-located-assets; do
        out_dir="$tmp_check/$(echo "$site_dir" | tr '/' '_')"
        typst compile --package-path "$tmp_pkg" --features html,bundle --format bundle "$site_dir/site.typ" "$out_dir"
    done

    # 2. Compile standalone HTML & paged PDF targets
    typst compile --package-path "$tmp_pkg" --features html --format html template/posts/fixed-points.typ "$tmp_check/fixed-points.html"
    typst compile --package-path "$tmp_pkg" template/posts/fixed-points.typ "$tmp_check/fixed-points.pdf"
    typst compile --package-path "$tmp_pkg" template/posts/minimal-bundles.typ "$tmp_check/minimal-bundles.pdf"
    typst compile --root . --package-path "$tmp_pkg" docs/manual.typ "$tmp_check/manual.pdf"

    # 3. Validate generated RSS/Atom XML and internal href targets across all bundles
    python3 - "$tmp_check" <<'PY'
    import pathlib, re, sys, xml.etree.ElementTree as ET
    base = pathlib.Path(sys.argv[1])
    for bundle in sorted(p for p in base.iterdir() if p.is_dir()):
        ET.fromstring((bundle / "atom.xml").read_text())
        ET.fromstring((bundle / "rss.xml").read_text())
        for html_file in sorted(bundle.rglob("*.html")):
            txt = html_file.read_text()
            assert ">??<" not in txt and "[??]" not in txt, f"unresolved ref in {html_file}"
            for href in re.findall(r'href="([^"#?]+)', txt):
                if href.startswith(("http://", "https://", "mailto:", "javascript:")):
                    continue
                target = (html_file.parent / href.lstrip("/")) if not href.startswith("/") else (bundle / href.lstrip("/"))
                assert target.resolve().exists(), f"broken href={href!r} in {html_file}"
    print("verified XML feeds and internal hrefs across all 4 bundles")
    PY

    # 4. Dry-run Universe directory staging
    sh ./scripts/stage-universe.sh --allow-vendored "$tmp_stage"

    if command -v typst-package-check >/dev/null 2>&1 && [ ! -d vendor/exemel ]; then
        typst-package-check check "$tmp_stage/packages/preview/$pkg_name/$pkg_ver"
    fi
    echo "all checks passed"

# Compile docs/manual.typ -> docs/manual.pdf
docs:
    #!/usr/bin/env sh
    set -eu
    tmp_pkg=".tmp-pkg"
    rm -rf "$tmp_pkg"
    trap 'rm -rf "$tmp_pkg"' EXIT
    pkg_name="$(sed -n 's/^name = "\(.*\)"/\1/p' typst.toml)"
    pkg_ver="$(sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)"
    mkdir -p "$tmp_pkg/preview/$pkg_name"
    ln -s "$(pwd)" "$tmp_pkg/preview/$pkg_name/$pkg_ver"
    for manifest in vendor/*/typst.toml; do
        [ -f "$manifest" ] || continue
        v_dir="$(cd "$(dirname "$manifest")" && pwd)"
        v_name="$(sed -n 's/^name = "\(.*\)"/\1/p' "$manifest")"
        v_ver="$(sed -n 's/^version = "\(.*\)"/\1/p' "$manifest")"
        mkdir -p "$tmp_pkg/preview/$v_name"
        ln -s "$v_dir" "$tmp_pkg/preview/$v_name/$v_ver"
    done
    typst compile --root . --package-path "$tmp_pkg" docs/manual.typ docs/manual.pdf
    echo "built docs/manual.pdf"

# Regenerate thumbnail.png (250 PPI) from template/posts/fixed-points.typ
thumbnail:
    #!/usr/bin/env sh
    set -eu
    tmp_pkg=".tmp-pkg"
    rm -rf "$tmp_pkg"
    trap 'rm -rf "$tmp_pkg"' EXIT
    pkg_name="$(sed -n 's/^name = "\(.*\)"/\1/p' typst.toml)"
    pkg_ver="$(sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)"
    mkdir -p "$tmp_pkg/preview/$pkg_name"
    ln -s "$(pwd)" "$tmp_pkg/preview/$pkg_name/$pkg_ver"
    for manifest in vendor/*/typst.toml; do
        [ -f "$manifest" ] || continue
        v_dir="$(cd "$(dirname "$manifest")" && pwd)"
        v_name="$(sed -n 's/^name = "\(.*\)"/\1/p' "$manifest")"
        v_ver="$(sed -n 's/^version = "\(.*\)"/\1/p' "$manifest")"
        mkdir -p "$tmp_pkg/preview/$v_name"
        ln -s "$v_dir" "$tmp_pkg/preview/$v_name/$v_ver"
    done
    typst compile --package-path "$tmp_pkg" -f png --pages 1 --ppi 250 template/posts/fixed-points.typ thumbnail.png
    if command -v oxipng >/dev/null 2>&1; then
        oxipng -o 4 --strip safe thumbnail.png
    fi
    echo "updated thumbnail.png"

# Stage clean Typst Universe directory -> public/universe/packages/preview/typica/<version>
stage-universe out="public/universe":
    sh ./scripts/stage-universe.sh "{{out}}"

# Link typica (and any vendor/*) into the local OS @preview package cache for editor LSPs
install-packages:
    #!/usr/bin/env sh
    set -eu
    if [ "$(uname -s)" = "Darwin" ]; then
        cache_root="$HOME/Library/Application Support/typst/packages"
    else
        cache_root="${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages"
    fi
    for manifest in typst.toml vendor/*/typst.toml; do
        [ -f "$manifest" ] || continue
        pkg_dir="$(cd "$(dirname "$manifest")" && pwd)"
        pkg_name="$(sed -n 's/^name = "\(.*\)"/\1/p' "$manifest")"
        pkg_ver="$(sed -n 's/^version = "\(.*\)"/\1/p' "$manifest")"
        mkdir -p "$cache_root/preview/$pkg_name"
        rm -rf "$cache_root/preview/$pkg_name/$pkg_ver"
        ln -s "$pkg_dir" "$cache_root/preview/$pkg_name/$pkg_ver"
        echo "linked @preview/$pkg_name:$pkg_ver -> $cache_root/preview/$pkg_name/$pkg_ver"
    done

# Bump package version across typst.toml, template/, examples/, docs/manual.typ, and README.md
bump version:
    #!/usr/bin/env python3
    import pathlib, re
    new_ver = "{{version}}".lstrip("v")
    if not re.fullmatch(r"\d+\.\d+\.\d+", new_ver):
        raise SystemExit(f"invalid semver: {new_ver!r}")
    toml = pathlib.Path("typst.toml")
    old_m = re.search(r'^version = "([^"]+)"', toml.read_text(), re.M)
    old_ver = old_m.group(1)
    toml.write_text(re.sub(r'^version = "[^"]+"', f'version = "{new_ver}"', toml.read_text(), count=1, flags=re.M))
    targets = (
        list(pathlib.Path("template").rglob("*.typ"))
        + list(pathlib.Path("examples").rglob("*.typ"))
        + [pathlib.Path("docs/manual.typ"), pathlib.Path("README.md")]
    )
    for p in targets:
        txt = p.read_text()
        txt = txt.replace(f"@preview/typica:{old_ver}", f"@preview/typica:{new_ver}")
        if p.name == "manual.typ":
            txt = txt.replace(f"v{old_ver}", f"v{new_ver}")
        p.write_text(txt)
    print(f"bumped typica {old_ver} -> {new_ver} (remember to run `just docs` and update CHANGELOG.md)")

# Commit, tag (vX.Y.Z), and push; GitHub Actions cuts the release and opens a Draft PR to typst/packages
release $tag="" $message="":
    #!/usr/bin/env sh
    set -eu

    tag="${tag:-}"
    message="${message:-}"

    if [ -z "$tag" ]; then
        printf 'release tag (e.g. v0.1.0): '
        read -r tag || tag=""
    fi
    if [ -z "$message" ]; then
        printf 'release message: '
        read -r message || message=""
    fi

    if [ -z "$tag" ] || [ -z "$message" ]; then
        echo "release: both tag and message are required" >&2
        exit 1
    fi
    case "$tag" in
        v*) ver="${tag#v}" ;;
        *) echo "release: tag must start with 'v' (e.g. v0.1.0)" >&2; exit 1 ;;
    esac

    toml_ver="$(sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)"
    if [ "$ver" != "$toml_ver" ]; then
        echo "release: tag $tag does not match typst.toml version $toml_ver (run 'just bump $ver' first)" >&2
        exit 1
    fi
    if ! git check-ref-format "refs/tags/$tag" >/dev/null 2>&1; then
        echo "release: '$tag' is not a valid git tag" >&2
        exit 1
    fi
    if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
        echo "release: tag $tag already exists" >&2
        exit 1
    fi
    if ! git remote get-url origin >/dev/null 2>&1; then
        echo "release: no 'origin' remote configured" >&2
        exit 1
    fi

    just check

    git add -A
    if ! git diff --cached --quiet; then
        git commit -m "$message"
    elif git rev-parse -q --verify HEAD >/dev/null; then
        echo "release: clean tree, tagging HEAD"
    else
        echo "release: nothing to commit and no commits yet" >&2
        exit 1
    fi

    git tag -a "$tag" -m "$message"
    git push origin HEAD
    git push origin "$tag"
    echo "release: pushed $tag"
