
#------------------------------------------------------------------------
#terraform {}bloco contém configurações do Terraform, incluindo os provedores 
#necessários que o Terraform usará para provisionar sua infraestrutura.
#------------------------------------------------------------------------
terraform {
  required_providers { #Você também pode definir uma restrição de versão para cada provedor definido no required_providersbloco. O versionatributo é opcional, mas recomendamos usá-lo para restringir a versão do provedor
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}
#------------------------------------------------------------------------
#O provider bloco: configura o provedor especificado, neste caso aws. Um provedor é 
#um plugin que o Terraform usa para criar e gerenciar seus recursos.
#------------------------------------------------------------------------
provider "aws" { 
  #Nunca codifique credenciais ou outros segredos em seus arquivos de configuração do Terraform
  profile = "default" # profile atributo no awsbloco do provedor refere-se ao Terraform às credenciais da AWS armazenadas em seu arquivo de configuração da AWS, que você criou quando configurou o AWS CLI (comando aws configure)
  region  = "us-west-2"
}

#------------------------------------------------------------------------
#Use resource blocos: para definir os componentes de sua infraestrutura. Um recurso 
#pode ser um componente físico ou virtual, como uma instância EC2, ou pode ser um 
#recurso lógico, como um aplicativo Heroku.
#------------------------------------------------------------------------
resource "aws_instance" "app_server" { 
  #ID exclusiva para o recurso. Por exemplo, o ID da sua instância EC2 é aws_instance.app_server.
  #Os blocos de recursos contêm argumentos que você usa para configurar o recurso. Os argumentos podem incluir coisas como tamanhos de máquina, nomes de imagem de disco ou IDs de VPC
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"
  tags = {
    Name = "ExampleAppServerInstance"
  }
}

resource "aws_api_gateway_rest_api" "minha_api_gateway" {
  name        = "Minha API"
  description = "AWS Rest API de exemplo com Terraform"
 endpoint_configuration {
   types = ["REGIONAL"]
  }
}
# compacta modulo hello world
data "archive_file" "lambda_hello_world" {
  type = "zip"

  source_dir  = "${path.module}/hello-world" #procura e pega o modulo (pasta) hello world
  output_path = "${path.module}/hello-world.zip" # compacta o modulo (pasta) hello wordem zip
}

#------------------------------------------------------------------------
# copiar a função para o nosso bucket S3;
# cria bucket para ser utilziado guardando nossa funcao lambda
#------------------------------------------------------------------------
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "lambdabucketteste"
  acl    = "private"
}

#------------------------------------------------------------------------
#resource utiliza bucket criado acima inserendio modulo hello world compactado
#------------------------------------------------------------------------
resource "aws_s3_bucket_object" "lambda_hello_world" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "hello-world.zip"
  source = data.archive_file.lambda_hello_world.output_path

  etag = filemd5(data.archive_file.lambda_hello_world.output_path)
}

#nspecionar o conteúdo do bucket do S3 : 

#------------------------------------------------------------------------
#Crie a função Lambda
#------------------------------------------------------------------------

#configura a função Lambda para usar o objeto de intervalo que contém seu código de função.
resource "aws_lambda_function" "hello_world" {
  function_name = "HelloWorld"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_bucket_object.lambda_hello_world.key

  runtime = "python3.7"
  handler = "hello-world.lambda_handler" # Quando sua função é chamada, o Lambda executa o método do manipulador (handler).

  source_code_hash = data.archive_file.lambda_hello_world.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

#define um grupo de log para armazenar mensagens de log de sua função Lambda por 30 dias. 
resource "aws_cloudwatch_log_group" "hello_world" {
  name = "/aws/lambda/${aws_lambda_function.hello_world.function_name}"

  retention_in_days = 30
}

#define uma função IAM que permite ao Lambda acessar recursos em sua conta AWS.define uma função IAM que permite ao Lambda acessar recursos em sua conta AWS.
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}
#anexa uma política à função IAM
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" #é uma política gerenciada pela AWS que permite que sua função Lambda grave em logs do CloudWatch.
}

#criar um valor de saída para o nome da sua função Lambda.
output "function_name" {
  description = "HelloWorld"

  value = aws_lambda_function.hello_world.function_name
}

#------------------------------------------------------------------------
# API HTTP com API Gateway
#------------------------------------------------------------------------

#define um nome para o API Gateway e define seu protocolo como HTTP
resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

#configura o API Gateway para usar sua função Lambda.
resource "aws_apigatewayv2_integration" "hello_world" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.hello_world.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

#mapeia uma solicitação HTTP para um destino, neste caso, sua função Lambda.
#route_keycorresponde a qualquer solicitação GET correspondente ao caminho /hello. 
#Uma targetcorrespondência integrations/<ID>mapeia para uma integração Lambda com o ID fornecido.
resource "aws_apigatewayv2_route" "hello_world" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello_world.id}"
}

#define um grupo de log para armazenar logs de acesso para o
resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

#concede permissão ao API Gateway para invocar sua função Lambda.
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

#valor de saída para este URL para outputs.tf.
output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.lambda.invoke_url
}

