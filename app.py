## API em Flask - Python

from flask import Flask, jsonify
from datetime import datetime
#from datetime import Datetime

# objeto cosntrutor do flask
app = Flask(__name__)




#Rota Hello Word
@app.route('/')
@app.route('/index')
def hello_word():
    return jsonify({
        'message:':'Hello Word! :D',
        'Author': 'Gabriel dos Santos Motroni',
        'Today': datetime.now()
    }), 200


#inicializador do flask
if __name__ == '__main__':
    app.run(debug=True)