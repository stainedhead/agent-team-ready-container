#!/usr/bin/env bash
set -euo pipefail

test "$(id -u)" = 1000
test "$(id -g)" = 1000
test "$HOME" = /home/vscode
test -w "$HOME"
test -w /workspace

for tool in g++ clang++ cmake make ninja vcpkg rustc cargo go java javac mvn gradle \
  python3 pipx uv dotnet node npm pnpm bun tsc git gh aws curl jq yq rg fd \
  chromium playwright sudo; do
  command -v "$tool" >/dev/null || { echo "missing $tool" >&2; exit 1; }
done

g++ --version | head -1
rustc --version
go version
java -version
python3 --version
dotnet --version
node --version
npm --version
pnpm --version
bun --version
tsc --version
gh --version | head -1
aws --version
chromium --version
playwright --version
test "$(printf 'value: ready\n' | yq '.value')" = ready

test_dir=$(mktemp -d /workspace/image-smoke.XXXXXX)
trap 'rm -rf "$test_dir"' EXIT
cd "$test_dir"

cat > hello.cc <<'EOF'
#include <expected>
#include <iostream>
int main() { std::expected<int, int> value = 23; std::cout << *value; }
EOF
g++ -std=c++23 hello.cc -o hello-cpp
test "$(./hello-cpp)" = 23

cargo new --quiet --bin hello-rust
(cd hello-rust && cargo run --quiet | grep -q 'Hello, world!')

mkdir hello-go
cat > hello-go/main.go <<'EOF'
package main
import "fmt"
func main() { fmt.Println("go-ready") }
EOF
(cd hello-go && go mod init example.com/smoke >/dev/null && go run . | grep -q go-ready)

cat > Hello.java <<'EOF'
public class Hello { public static void main(String[] args) { System.out.print("java-ready"); } }
EOF
javac --release 25 Hello.java
test "$(java Hello)" = java-ready
[[ "$(java -version 2>&1 | head -1)" == *'25.'* ]]

python3 -m venv python-venv
python-venv/bin/python -c 'import sys; assert sys.prefix != sys.base_prefix'

dotnet new console -n hello-dotnet --no-restore >/dev/null
dotnet run --project hello-dotnet | grep -q 'Hello, World!'

cat > hello.ts <<'EOF'
const message: string = 'typescript-ready';
console.log(message);
EOF
tsc --target ES2022 --outDir js hello.ts
test "$(node js/hello.js)" = typescript-ready

node <<'EOF'
const { chromium } = require('@playwright/test');
(async () => {
  const browser = await chromium.launch({headless: true});
  const page = await browser.newPage();
  await page.setContent('<h1>browser-ready</h1>');
  if (await page.locator('h1').textContent() !== 'browser-ready') throw new Error('browser failed');
  await browser.close();
})().catch(error => { console.error(error); process.exit(1); });
EOF

if [[ "${INSTALL_SMOKE:-0}" == 1 ]]; then
  mkdir bun-project
  (cd bun-project && bun init -y >/dev/null && bun add --dev is-number@7.0.0 >/dev/null && test -d node_modules/is-number)
  uv pip install --python python-venv/bin/python packaging
  python-venv/bin/python -c 'import packaging'
  (cd hello-rust && cargo add regex@1 && cargo check --quiet)
  sudo -n apt-get update >/dev/null
  sudo -n apt-get install -y --no-install-recommends cowsay >/dev/null
  dpkg -s cowsay >/dev/null
fi

echo 'image smoke test passed'
