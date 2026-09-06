const { chromium } = require(process.env.PW || 'playwright');
(async () => {
  const b = await chromium.launch(); const page = await b.newPage();
  for (const p of ['investor-ready.html','diagnostic.html','transaction-readiness.html','ethical-acquisitions.html']) {
    await page.goto('file://' + require('path').resolve(__dirname, '..') + '/' + p); await page.waitForTimeout(200);
    await page.evaluate(() => { const names = [...new Set([...document.querySelectorAll('input[type=radio]')].map(r => r.name))]; names.forEach((n, i) => { const o = document.querySelectorAll(`input[name="${n}"]`); o[Math.min(o.length - 1, (i % 3) + 1)].click(); }); });
    await page.click(p === 'investor-ready.html' ? '#submit-btn' : 'button.cta'); await page.waitForTimeout(200);
    await page.evaluate(() => document.getElementById('ld-name').focus());
    await page.keyboard.type('Test Founder'); await page.keyboard.press('Tab'); await page.keyboard.type('founder@example.co.uk'); await page.keyboard.press('Tab'); await page.keyboard.type('Example Ltd');
    // remaining selects: ArrowDown each, then the checkbox, then the button
    let guard = 0;
    while (guard++ < 6) { await page.keyboard.press('Tab'); const t = await page.evaluate(() => document.activeElement.tagName + '#' + document.activeElement.id); if (t.startsWith('SELECT')) await page.keyboard.press('ArrowDown'); else if (t === 'INPUT#ld-consent') { await page.keyboard.press('Space'); break; } }
    await page.keyboard.press('Tab');
    const onBtn = await page.evaluate(() => document.activeElement.tagName + ':' + document.activeElement.textContent.trim());
    const t0 = Date.now(); await page.keyboard.press('Enter');
    await page.waitForFunction(() => document.getElementById('fullReport').style.display === 'block', null, { timeout: 15000 }).catch(() => {});
    const r = await page.evaluate(() => ({ full: document.getElementById('fullReport').style.display, err: document.getElementById('ld-error').textContent }));
    console.log(p, '| Enter pressed on:', onBtn, '| report:', r.full, 'after', Date.now() - t0, 'ms', r.err ? '| err: ' + r.err : '');
  }
  await b.close();
})();
