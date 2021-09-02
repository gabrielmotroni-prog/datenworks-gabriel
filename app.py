## API em Flask - Python

#from flask import Flask, jsonify
from flask import Flask

#from datetime import datetime
#from datetime import Datetime

# objeto cosntrutor do flask
app = Flask(__name__)


#Rota Hello Word
@app.route('/')
@app.route('/index')
def hello_word():
    '''   return jsonify({
        'message:':'Hello Word! :D',
        'Author': 'Gabriel dos Santos Motroni',
        'Today': 'datetime.now()'
    }), 200'''
    return "hello word!"
 


#inicializador do flask
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')