#Dockerfile

FROM python:3.8.5-alpine3.12

#é usado para definir o diretório de trabalho de um contêiner 
#do Docker a qualquer momento. 
WORKDIR /datenworkes-gabriel

#Expõem uma ou mais portas, isso quer dizer que o container quando iniciado 
#poderá ser acessível através dessas portas
EXPOSE 5000

#explicita quem eh a variavel ambiente do flask.
#istrução que cria e atribui um valor para uma 
#variável dentro da imagem,
ENV FLASK_APP=app

COPY . /datenworkes-gabriel

RUN pip install -r requirements.txt

#Quando um container for inicializado, o que será 
#executado é a  soma de Entrypoint e CMD.
ENTRYPOINT [ "flask"]
CMD [ "run", "--host", "0.0.0.0" ] 
# flask run --host '0.0.0.0'



