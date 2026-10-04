const assert = require('node:assert/strict');
const fs = require('node:fs');
const { chromium } = require('@playwright/test');

async function main() {
  assert.equal(process.getuid(), 1000);
  for (const name of ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'GH_TOKEN', 'GITHUB_TOKEN']) {
    assert.equal(process.env[name], undefined, `${name} reached the browser container`);
  }
  for (const path of ['/home/vscode/.aws/credentials', '/home/vscode/.docker/config.json']) {
    assert.equal(fs.existsSync(path), false, `${path} reached the browser container`);
  }

  const browser = await chromium.launch({ headless: true, chromiumSandbox: true });
  try {
    const page = await browser.newPage();
    await page.setContent('<h1>browser-sandbox-ready</h1>');
    assert.equal(await page.locator('h1').textContent(), 'browser-sandbox-ready');

    const parentNamespace = fs.readlinkSync('/proc/self/ns/user');
    const renderers = fs.readdirSync('/proc')
      .filter(pid => /^\d+$/.test(pid))
      .flatMap(pid => {
        try {
          const cmdline = fs.readFileSync(`/proc/${pid}/cmdline`, 'utf8');
          if (!cmdline.includes('chrome-headless-shell') || !cmdline.includes('--type=renderer')) return [];
          assert.equal(cmdline.includes('--no-sandbox'), false);
          return [{ pid, namespace: fs.readlinkSync(`/proc/${pid}/ns/user`) }];
        } catch (error) {
          if (error.code === 'ENOENT') return [];
          throw error;
        }
      });
    const sandboxedRenderers = renderers.filter(renderer => renderer.namespace !== parentNamespace);
    assert.ok(sandboxedRenderers.length > 0, 'no renderer entered a separate user namespace');
    console.log(`browser sandbox passed: ${sandboxedRenderers.length} renderer(s) in a separate user namespace`);
  } finally {
    await browser.close();
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
