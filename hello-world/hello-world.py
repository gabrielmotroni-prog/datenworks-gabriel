"""Python AWS Lambda Hello World exemplo esta exemplo de funcao Lambda  vai retornar um ' Hello Word' e
   um HTTP Status Code 200. So lembrando de deixar seus projeto .py em modulo (pasta)
"""

import json

'''
O manipulador(handler) de função Lambda é o método em seu código de função que processa 
eventos. Quando sua função é chamada, o Lambda executa o método do manipulador(handler) .
'''
def lambda_handler(event, context):
      return {
        'statusCode': 200,
        'body': json.dumps('Hello world :D ! by: Gabriel dos Santos Motroni'),
        'headers':{
            'Content-Type': 'application/json'
        }
    }

