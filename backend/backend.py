from flask import Flask, request, jsonify
import re
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Initialize Firebase Admin SDK
cred = credentials.Certificate("config/budget-alert-20ced-firebase-adminsdk-pdxdj-dc2b845c25.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

app = Flask(__name__)

@app.route('/receive_sms', methods=['POST'])
def receive_sms():
    data = request.json
    sms_body = data.get('smsBody')  # Extract the SMS body from the request
    bank = data.get('bank')
    date = data.get('date')

    # For testing purposes
    sms_body_test = 'Dear Cardholder, Purchase at MP Centauri Technology HoAmsterdam NL for LKR 950.00 on 16/03/24 03:00 PM has been authorised on your debit card ending #3901.'
    bank_test = 'COMBANK'

    transaction_details = extract_transaction_details(sms_body, bank, date)
    
    print("Transaction Details:", transaction_details)

    if transaction_details:
        store_transaction_details(transaction_details)

    return jsonify({'message': 'SMS received and processed successfully'}), 200

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

def extract_transaction_details(sms_body, bank, date):
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
            transaction_details['account'] = find_account_by_last_four_digits(int(card))

        if re.search('Credit for', sms_body):
            transaction_details['type'] = 'INCOME'
            transaction_details['currency'] = 'LKR'
            amount_string = re.findall('\D{2,3}\s([\d+,]+\.\d{2})', sms_body)[0]
            amount_float = float(amount_string.replace(',', ''))
            transaction_details['amount'] = amount_float
            branch_name = re.findall('at (\D+)', sms_body)[0]
            transaction_details['description'] = f'Credit from {branch_name}'
            transaction_details['date'] = format_date(date)
            transaction_details['account'] = re.findall('to (\d+) at', sms_body)[0]

        if re.search('CRM Deposit|CRC Deposit', sms_body):
            transaction_details['type'] = 'INCOME'
            transaction_details['currency'] = 'LKR'
            amount_string = re.findall('\D{2,3}\s([\d+,]+\.\d{2})', sms_body)[0]
            amount_float = float(amount_string.replace(',', ''))
            transaction_details['amount'] = amount_float
            branch_name = re.findall('through\s+(\S+\s*-\s*\S+)\s+BR', sms_body)[0]
            transaction_details['description'] = f'CRM Deposit from {branch_name}'
            transaction_details['date'] = format_date(date)
            transaction_details['account'] = re.findall('account\s+(\d+\D+\d+)', sms_body)[0]

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
            transaction_details['account'] = find_account_by_last_four_digits(int(card))

    return transaction_details

def find_account_by_last_four_digits(card_number):
    accounts_ref = db.collection('accounts').where('lastFourDigits', '==', card_number).limit(1).get()
    for account in accounts_ref:
        return account.to_dict()['accountNumber']
    return None

def store_transaction_details(transaction_details):
    db.collection('transactions').add(transaction_details)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
