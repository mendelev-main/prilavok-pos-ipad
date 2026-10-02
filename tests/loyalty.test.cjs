const test=require("node:test"),assert=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const html=fs.readFileSync(path.join(__dirname,"../PrilavokPOS/pos.html"),"utf8");
const loyalty=fs.readFileSync(path.join(__dirname,"../PrilavokPOS/Web/js/features/loyalty.js"),"utf8");
const payment=fs.readFileSync(path.join(__dirname,"../PrilavokPOS/Web/js/features/payment.js"),"utf8");
const receipts=fs.readFileSync(path.join(__dirname,"../PrilavokPOS/Web/js/features/receipts.js"),"utf8");
test("POS exposes customer search and loyalty balance",()=>{assert.match(loyalty,/openCustomerPicker/);assert.match(loyalty,/\/api\/customers\/search/);assert.match(loyalty,/\/loyalty/);assert.match(loyalty,/Прогресс:/);assert.match(loyalty,/Подарков:/)});
test("loyalty is published only from finalized payment path",()=>{const finalize=payment.slice(payment.indexOf("function finalizePayment"),payment.indexOf("function openCashModal"));assert.match(finalize,/publishPaidOrderLoyalty\(order\)/);assert.match(payment,/loyaltySync=\{status:'pending'/)});
test("reward selection is bounded by server-provided balance",()=>{assert.match(loyalty,/Array\.from\(\{length:Number\(p\.rewards\)\}/);assert.match(loyalty,/loyaltyRedemptions/)});

test("reward discount is separated from product base price",()=>{assert.match(loyalty,/function loyaltyRewardDiscount/);assert.match(loyalty,/Программа лояльности/);assert.match(html,/Math\.max\(0,cartSubtotal\(\).*loyaltyRewardDiscount\(\)/s)});
test("paid loyalty has ordered reconnect retry and refund reversal",()=>{assert.match(loyalty,/function retryPendingLoyalty/);assert.match(loyalty,/function settleReturnedOrderLoyalty/);assert.match(loyalty,/\/api\/loyalty\/reversal/);assert.match(receipts,/processFullReturn[\s\S]*settleReturnedOrderLoyalty\(committedOrder\)/)});
test("admin panel exposes customers and loyalty programs",()=>{assert.match(loyalty,/openCustomersAdmin/);assert.match(loyalty,/openLoyaltyAdmin/);assert.match(loyalty,/Новая программа/);assert.match(loyalty,/Клиенты/)});
test('offline POS keeps normal payment available while reward redemption requires server confirmation',()=>{assert.match(payment,/Продажу и оплату можно продолжить без интернета/);assert.match(payment,/Продолжить без подарка/);assert.match(payment,/revalidateSelectedLoyaltyReward/);});
test('pending loyalty reversals retry after reconnect',()=>{assert.match(loyalty,/loyaltyReversal\?\.status==='pending'/);assert.match(loyalty,/void settleReturnedOrderLoyalty\(order\)/);});
