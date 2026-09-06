// Live end-to-end from a real browser: answer, report, opt-in, insert, send-report. Needs a network path for Chromium; in a proxied sandbox use live-lead-test.mjs instead.
const { chromium } = require(process.env.PW || 'playwright');
(async () => {
  const b = await chromium.launch({ proxy: { server: process.env.HTTPS_PROXY } }); const ctx = await b.newContext({ ignoreHTTPSErrors: true }); const page = await ctx.newPage();
  const net = []; page.on('response', async r => { const u = r.url(); if (/supabase\.co/.test(u)) { let body = ''; try { body = (await r.text()).slice(0, 160); } catch (e) {} net.push({ url: u.replace(/^https:\/\/[^/]+/, ''), status: r.status(), body }); } });
  page.on('pageerror', e => net.push({ pageerror: e.message }));
  for (const [p, fill] of [
    ['investor-ready.html', () => { questionBank.forEach((q, i) => document.querySelector(`input[name=${q.id}][value="${[1,2,3,4][i % 4]}"]`).click()); }],
    ['diagnostic.html', () => { for (let i = 0; i < 20; i++) document.querySelector(`input[name=q${i}][value="${[3,4,2,5,3][i % 5]}"]`).click(); }],
  ]) {
    await page.goto('file://' + require('path').resolve(__dirname, '..') + '/' + p + '?utm_source=Referral'); await page.waitForTimeout(300);
    await page.evaluate(fill);
    await page.click(p === 'investor-ready.html' ? '#submit-btn' : 'button.cta'); await page.waitForTimeout(300);
    const before = await page.evaluate(() => ({ full: document.getElementById('fullReport').style.display, gateShown: getComputedStyle(document.getElementById('leadgate')).display !== 'none', gateAfterReport: document.getElementById('fullReport').nextElementSibling === document.getElementById('leadgate') }));
    await page.evaluate(() => { document.getElementById('ld-name').value = 'QA Test'; document.getElementById('ld-email').value = 'qa-test-delete-me@example.com'; document.getElementById('ld-company').value = 'Northwind Components Ltd (TEST)'; var r = document.getElementById('ld-role'); if (r) r.selectedIndex = 1; document.getElementById('ld-revenue').selectedIndex = 2; document.getElementById('ld-consent').checked = true; });
    const t0 = Date.now(); await page.evaluate(() => submitLead());
    await page.waitForFunction(() => /On its way/.test(document.getElementById('leadgate').textContent), null, { timeout: 15000 }).catch(() => {});
    const after = await page.evaluate(() => ({ sent: /On its way/.test(document.getElementById('leadgate').textContent), msg: document.getElementById('leadgate').textContent.trim().slice(0, 90) }));
    console.log(p, '| before:', JSON.stringify(before), '| after', Date.now() - t0, 'ms:', JSON.stringify(after));
  }
  console.log('network:'); net.forEach(n => console.log(' ', JSON.stringify(n)));
  await b.close();
})();
