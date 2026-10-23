"""HTTP integration checks against the running local demo server (uses test orders)."""
from urllib.request import build_opener, HTTPCookieProcessor
from urllib.parse import urlencode
from http.cookiejar import CookieJar
import re, os
base=os.environ.get('PRINT_SHOP_TEST_URL','http://localhost:8081')
log=[]
def client(): return build_opener(HTTPCookieProcessor(CookieJar()))
a,b=client(),client()
def get(c): return c.open(base).read().decode()
def post(c, action, **fields):
    page=get(c)
    token=re.search(r'name="token" value="([^"]+)"',page).group(1)
    return c.open(base+'/action',urlencode(dict(token=token,action=action,**fields)).encode()).read().decode()
def check(condition,label):
    assert condition,label
    log.append('PASS '+label)
post(a,'new');post(b,'new')
page=post(a,'answer',key='pages',value='oops')
check('invalid_answer' in page and 'Pages per copy' in page,'invalid answer retained question')
for k,v in [('pages',40),('copies',3),('colour','no'),('duplex','yes'),('bound','yes'),('binding','spiral'),('budget',1020),('deadline','none')]:
    page=post(a,'answer',key=k,value=v)
check('Pages per copy' in get(b),'separate browser sessions do not share answers')
for material,quantity in [('paper',80),('spiral',10),('staple',30)]:
    post(a,'stock',operation='set',material=material,quantity=quantity)
page=get(a)
check('LKR 1020' in page,'expected quote appears')
post(b,'stock',operation='set',material='paper',quantity=0)
# Use previously rendered quote; the stored draft is re-evaluated at confirmation.
page=post(a,'confirm',choice=1)
check('Could not complete' in page,'unavailable quote cannot be confirmed')
post(b,'stock',operation='set',material='paper',quantity=80)
page=post(a,'confirm',choice=1)
check('confirmed.' in page,'order confirmation succeeds')
id=int(re.search(r'Order (\d+) confirmed',page).group(1))
check('>20<' in page and '>7<' in page,'paper and binding stock deducted')
page=post(a,'confirm',choice=1)
check('Could not complete' in page,'duplicate confirmation rejected')
page=post(a,'cancel',id=id)
check('stock returned' in page and '>80<' in page,'cancellation restores stock')
page=post(a,'cancel',id=id)
check('unknown_order' in page,'duplicate cancellation rejected')
page=post(a,'stock',operation='set',material='ink',quantity=10)
check('invalid_stock' in page,'unknown stock material rejected')
page=post(a,'stock',operation='set',material='paper',quantity='abc')
check('invalid_quantity' in page,'nonnumeric stock rejected')
page=post(a,'stock',operation='remove',material='staple')
check('Stock updated' in page,'stock removal succeeds')
page=post(a,'stock',operation='add',material='staple',quantity=30)
check('Stock updated' in page,'stock addition succeeds')
page=a.open(base+'/action',urlencode(dict(token='invalid',action='new')).encode()).read().decode()
check('invalid_form' in page,'invalid form token rejected')
page=post(a,'new')
for k,v in [('pages',1),('copies',1),('colour','no'),('duplex','no'),('bound','no')]:
    page=post(a,'answer',key=k,value=v)
check('Budget in whole' in page,'binding question skipped when unnecessary')
post(a,'new')
for k,v in [('pages',40),('copies',3),('colour','no'),('duplex','yes'),('bound','yes'),('binding','spiral'),('budget',1020)]:
    page=post(a,'answer',key=k,value=v)
page=post(a,'answer',key='deadline',value='2026-02-30 09:00')
check('invalid_answer' in page,'invalid deadline date rejected')
page=post(a,'answer',key='deadline',value='2026-10-23 09:16')
check('Deadline cannot be met' in page and '09:17' in page,'earliest completion shown for missed deadline')
post(a,'new')
for k,v in [('pages',40),('copies',3),('colour','no'),('duplex','yes'),('bound','yes'),('binding','spiral'),('budget',1020),('deadline','2026-10-23 09:17')]:
    page=post(a,'answer',key=k,value=v)
check('17 working minutes' in page and '09:17' in page,'duration and finish shown in quote')
page=post(a,'confirm',choice=1)
check('confirmed' in page and 'deadline 2026-10-23 09:17' in page,'confirmed schedule and deadline displayed')
new_id=int(re.search(r'Order (\d+) confirmed',page).group(1))
post(b,'stock',operation='add',material='paper',quantity=60)
post(b,'new')
for k,v in [('pages',40),('copies',3),('colour','no'),('duplex','yes'),('bound','yes'),('binding','spiral'),('budget',1020),('deadline','2026-10-23 09:20')]:
    page=post(b,'answer',key=k,value=v)
check('Deadline cannot be met' in page and '09:34' in page,'another session sees queue delay')
post(a,'cancel',id=new_id)
post(a,'new');post(b,'new')
print('\n'.join(log))
