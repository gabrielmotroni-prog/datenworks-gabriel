
# app.py
from flask import Flask, jsonify
from datetime import datetime

app = Flask(__name__)

@app.route("/")
def helo_word():
    return jsonify({
        'message:':'Hello Word! :D',
        'Author': 'Gabriel dos Santos Motroni',
        'Today': datetime.utcnow()
    }), 200


if __name__ == "__main__":
    app.run(debug=True)


#para testar no bash:
# FLASK_APP=app
#flask run --host '0.0.0.0'