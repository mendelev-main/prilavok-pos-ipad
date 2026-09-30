const test=require("node:test"),assert=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const html=fs.readFileSync(path.join(__dirname,"../PrilavokPOS/pos.html"),"utf8");
test("POS exposes customer search and loyalty balance",()=>{assert.match(html,/openCustomerPicker/);assert.match(html,/\/api\/customers\/search/);assert.match(html,/\/loyalty/);assert.match(html,/Прогресс:/);assert.match(html,/Подарков:/)});
test("loyalty is published only from finalized payment path",()=>{const finalize=html.slice(html.indexOf("function finalizePayment"),html.indexOf("function openCashModal"));assert.match(finalize,/publishPaidOrderLoyalty\(order\)/);assert.match(html,/loyaltySync=\{status:'pending'/)});
test("reward selection is bounded by server-provided balance",()=>{assert.match(html,/Array\.from\(\{length:Number\(p\.rewards\)\}/);assert.match(html,/loyaltyRedemptions/)});
