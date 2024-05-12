from flask import Flask, request, jsonify
import re
import firebase_admin
import uuid
from firebase_admin import credentials, firestore
from datetime import datetime


#initialize firebase admin SDK
cred = credentials.Certificate("config/budget-alert-20ced-firebase-adminsdk-pdxdj-dc2b845c25.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

app = Flask(__name__)

@app.route('/receive_sms', methods=['POST'])
def receive_sms():
    data = request.json
    sms_body = data.get('smsBody')  #extract the SMS body from the request
    bank = data.get('bank')
    date = data.get('date')
    uid = data.get('uid')

    transaction_details = extract_transaction_details(sms_body, bank, date, uid)
    
    print("Transaction Details:", transaction_details)


    if transaction_details:
        #check if a similar transaction already exists
        if not is_duplicate_transaction(transaction_details):
            store_transaction_details(transaction_details)
        else:
            print("Duplicate transaction. Not storing.")

    return jsonify({'message': 'SMS received and processed successfully'}), 200

@app.route('/rescan', methods=['POST'])
def rescan():
    # delete all existing transactions
    delete_existing_transactions()
    return jsonify({'message': 'Existing transactions deleted for rescan'}), 200

def format_date(date_string):
    try:
        date = datetime.fromisoformat(date_string)
    except ValueError:
        try:
            date = datetime.strptime(date_string, "%d/%m/%y %I:%M %p")
        except ValueError:
            return None
        
    formatted_date = date.strftime("%Y-%m-%d %H:%M")

    return formatted_date

def extract_transaction_details(sms_body, bank, date, uid):
    transaction_details = {}
    if bank == 'COMBANK':
        if re.search('Purchase at', sms_body):
            transaction_details['type'] = 'EXPENSE'
            transaction_details['description'] = re.findall('Purchase at (.+) for', sms_body)[0]
            transaction_details['currency'] = re.findall('for ([A-Z]{3})', sms_body)[0]
            amount_string = re.findall('[A-Z]{3} ([\d,]+\.\d{2})', sms_body)[0]
            amount_float = float(amount_string.replace(',', ''))
            transaction_details['amount'] = amount_float
            date_string = re.findall('\d{2}\/\d{2}\/\d{2} \d{2}\:\d{2} [APM]{2}', sms_body)[0]
            transaction_details['date'] = format_date(date_string)
            card = re.findall('#(\d{4})', sms_body)[0]
            transaction_details['account'] = find_account_by_card(card)
            transaction_details['uid'] = uid

        if re.search('Credit for', sms_body):
            transaction_details['type'] = 'INCOME'
            transaction_details['currency'] = 'LKR'
            amount_string = re.findall('\D{2,3}\s([\d+,]+\.\d{2})', sms_body)[0]
            amount_float = float(amount_string.replace(',', ''))
            transaction_details['amount'] = amount_float
            branch_name = re.findall('at (\D+)', sms_body)[0]
            transaction_details['description'] = f'Credit from {branch_name}'
            transaction_details['date'] = format_date(date)
            account_number = re.findall('to (\d+) at', sms_body)[0]
            transaction_details['account'] = find_account_by_acc_number(account_number)
            transaction_details['uid'] = uid

        if re.search('CRM Deposit|CRC Deposit', sms_body):
            transaction_details['type'] = 'INCOME'
            transaction_details['currency'] = 'LKR'
            amount_string = re.findall('\D{2,3}\s([\d+,]+\.\d{2})', sms_body)[0]
            amount_float = float(amount_string.replace(',', ''))
            transaction_details['amount'] = amount_float
            branch_name = re.findall('through\s+(\S+\s*-\s*\S+)\s+BR', sms_body)[0]
            transaction_details['description'] = f'CRM Deposit from {branch_name}'
            transaction_details['date'] = format_date(date)
            account_string = re.findall('account\s[\d*Xx]+(\d{4})', sms_body)[0]
            transaction_details['account'] = find_account_by_last_four_digits(account_string)
            transaction_details['uid'] = uid

        if re.search('Withdrawal at', sms_body):
            transaction_details['type'] = 'ATM Withdrawal'
            transaction_details['currency'] = 'LKR'
            amount_string = re.findall('\D{2,3}\s([\d+,]+\.\d{2})', sms_body)[0]
            amount_float = float(amount_string.replace(',', ''))
            transaction_details['amount'] = amount_float
            atm_name = re.findall('Withdrawal at (.+?) for', sms_body)[0]
            transaction_details['description'] = f'Withdrawal from {atm_name}'
            date_string = re.findall('\d{2}\/\d{2}\/\d{2} \d{2}\:\d{2} [APM]{2}', sms_body)[0]
            transaction_details['date'] = format_date(date_string)
            card = re.findall('#(\d{4})', sms_body)[0]
            transaction_details['account'] = find_account_by_card(card)
            transaction_details['uid'] = uid

    return transaction_details

def is_duplicate_transaction(transaction_details):
    # check if a similar transaction already exists
    transactions_ref = db.collection('transactions')\
        .where('date', '==', transaction_details['date'])\
        .where('uid', '==', transaction_details['uid'])\
        .limit(1).get()
    return len(transactions_ref) > 0

def delete_existing_transactions():
    # delete all existing transactions
    transactions_ref = db.collection('transactions').get()
    for transaction in transactions_ref:
        db.collection('transactions').document(transaction.id).delete()

def find_account_by_card(card_number):
    accounts_ref = db.collection('accounts').where('cardNumber', '==', card_number).limit(1).get()
    for account in accounts_ref:
        return account.to_dict()['account']
    return None

def find_account_by_last_four_digits(last_digits):
    accounts_ref = db.collection('accounts').where('lastFourDigits', '==', last_digits).limit(1).get()
    for account in accounts_ref:
        return account.to_dict()['account']
    return None

def find_account_by_acc_number(acc_number):
    accounts_ref = db.collection('accounts').where('accountNumber', '==', acc_number).limit(1).get()
    for account in accounts_ref:
        return account.to_dict()['account']
    return None

def store_transaction_details(transaction_details):
    transaction_details['transaction_id'] = str(uuid.uuid4())
    db.collection('transactions').add(transaction_details)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)
