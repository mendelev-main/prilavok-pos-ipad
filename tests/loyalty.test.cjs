const test=require("node:test"),assert=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const html=fs.readFileSync(path.join(__dirname,"../PrilavokPOS/pos.html"),"utf8");
test("POS exposes customer search and loyalty balance",()=>{assert.match(html,/openCustomerPicker/);assert.match(html,/\/api\/customers\/search/);assert.match(html,/\/loyalty/);assert.match(html,/Прогресс:/);assert.match(html,/Подарков:/)});
test("loyalty is published only from finalized payment path",()=>{const finalize=html.slice(html.indexOf("function finalizePayment"),html.indexOf("function openCashModal"));assert.match(finalize,/publishPaidOrderLoyalty\(order\)/);assert.match(html,/loyaltySync=\{status:'pending'/)});
test("reward selection is bounded by server-provided balance",()=>{assert.match(html,/Array\.from\(\{length:Number\(p\.rewards\)\}/);assert.match(html,/loyaltyRedemptions/)});

test("reward discount is separated from product base price",()=>{assert.match(html,/function loyaltyRewardDiscount/);assert.match(html,/Программа лояльности/);assert.match(html,/Math\.max\(0,cartSubtotal\(\).*loyaltyRewardDiscount\(\)/s)});
test("paid loyalty has reconnect retry and refund reversal",()=>{assert.match(html,/function retryPendingLoyalty/);assert.match(html,/function reverseOrderLoyalty/);assert.match(html,/\/api\/loyalty\/reversal/);assert.match(html,/processFullReturn[\s\S]*reverseOrderLoyalty\(order\)/)});
test("admin panel exposes customers and loyalty programs",()=>{assert.match(html,/openCustomersAdmin/);assert.match(html,/openLoyaltyAdmin/);assert.match(html,/Новая программа/);assert.match(html,/Клиенты/)});
test('offline POS keeps normal payment available while reward redemption requires server confirmation',()=>{assert.match(html,/Продажу и оплату можно продолжить без интернета/);assert.match(html,/Продолжить без подарка/);assert.match(html,/revalidateSelectedLoyaltyReward/);});
test('pending loyalty reversals retry after reconnect',()=>{assert.match(html,/loyaltyReversal\?\.status==='pending'/);assert.match(html,/void reverseOrderLoyalty\(order\)/);});
