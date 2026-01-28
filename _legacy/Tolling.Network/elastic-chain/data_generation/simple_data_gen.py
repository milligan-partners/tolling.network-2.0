import json
import random
import sys
import uuid
import time as timelibrary
from datetime import datetime

def randomDate(start, end):
    frmt = '%d-%m-%Y %H:%M:%S'

    stime = timelibrary.mktime(timelibrary.strptime(start, frmt))
    etime = timelibrary.mktime(timelibrary.strptime(end, frmt))

    ptime = stime + random.random() * (etime - stime)
    dt = datetime.fromtimestamp(timelibrary.mktime(timelibrary.localtime(ptime)))
    return dt

agencies = ['tc', 'at', 'sd']
statuses = ['paid', 'unpaid']
tag_status = ['non_revenue', 'valid', 'invalid']
last_changes = ['create', 'update']
action_codes = ['active', 'delete']
tag_types = ['tag', 'pay_by_plate']
tag_ids = []
data = []
axles=[2,4]

n_els = 300 if len(sys.argv) < 2 else int(sys.argv[1])
start_date = '-3d' if len(sys.argv) < 3 else sys.argv[2]
end_date = '-1d' if len(sys.argv) < 4 else sys.argv[3]

print('Generating', n_els, 'elements', 'with start_date', start_date, 'with end_date', end_date)

for i in range(1, n_els // 3):
    if i % 100 == 0:
        print(i)
    tag_hash = str(uuid.uuid4())
    tag_id = 'tag-' + tag_hash
    acc_id = 'acc-' + tag_hash
    tag_ids.append(tag_id)
    source = random.choice(agencies)
    sts = random.choice(tag_status)
    t = random.choice(tag_types)
    date = randomDate(start_date, end_date)
    time = date.strftime('%H:%M:%S')
    date = date.strftime('%m/%d/%Y')
    last_change = 'update'
    action_code = 'delete'
    if sts != 'invalid':
        last_change = random.choice(last_changes)
        action_code = 'active'

    data.append({
        'account_id': acc_id,
        'tag_id': tag_id,
        'source': source,
        'tag_status': sts,
        'date': date,
        'last_change': last_change,
        'time': time,
        'action_code': action_code,
        'tag_type': t,
        'tag_status': sts
    })


with open('tags.json', 'w') as f:
    f.write(json.dumps(data))


data = []
for i in range(1, n_els):
    if i % 100 == 0:
        print(i)
    tx_hash = str(uuid.uuid4())
    t_id = 'tx-' + tx_hash
    tag_id = random.choice(tag_ids)
    source, destination = random.sample(agencies, 2)
    sts = random.choice(statuses)
    amount = random.uniform(10, 45)
    date = randomDate(start_date, end_date)
    time = date.strftime('%H:%M:%S')
    date = date.strftime('%m/%d/%Y')
    t = random.choice(tag_types)
    axle = random.choice(axles)
    data.append({
    'type': t,
    'transaction_id': t_id,
    'tag_id': tag_id,
    'source': source,
    'destination': destination,
    'axle': axle,
    'fee': 0.0,
    'status': sts,
    'amount': amount,
    'date': date,
    'time': time
    })


with open('toll_charges.json', 'w') as f:
    f.write(json.dumps(data))
