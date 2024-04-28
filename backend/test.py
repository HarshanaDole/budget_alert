from flask import Flask, jsonify
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin SDK
cred = credentials.Certificate("config/budget-alert-20ced-firebase-adminsdk-pdxdj-dc2b845c25.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

app = Flask(__name__)

@app.route('/get_accounts', methods=['GET'])
def get_accounts():
    # Create an empty list to store account data
    all_accounts = []

    # Retrieve all documents from the "accounts" collection
    accounts_ref = db.collection('accounts')
    accounts = accounts_ref.stream()

    # Iterate over each document and add its data to the list
    for account in accounts:
        account_data = account.to_dict()
        all_accounts.append(account_data)

    return jsonify({'accounts': all_accounts}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
