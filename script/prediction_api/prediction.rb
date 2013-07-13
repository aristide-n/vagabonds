#!/usr/bin/env ruby

require 'google/api_client'
#require 'sinatra'

#enable :sessions

# Project credentials
# ------------------------
DATA_OBJECT = "activitybucket/activity_prediction_data.txt" # This is the {bucket}/{object} name you are using for the language file.
CLIENT_EMAIL = "248144510891@developer.gserviceaccount.com" # Email of service account
KEYFILE = '../96534c5b34584996aa30632c51636b25fd64b494-privatekey.p12' # Filename of the private key
PASSPHRASE = 'notasecret' # Passphrase for private key
# ------------------------

def configure
  @client = Google::APIClient.new

  #We must tell ruby to read the keyfile in binary mode.
  content = File.read(KEYFILE, :mode => 'rb')

  pkcs12 = OpenSSL::PKCS12.new(content, PASSPHRASE)
  key = pkcs12.key

  # Authorize service account
  #key = Google::APIClient::PKCS12.load_key(KEYFILE, PASSPHRASE)
  asserter = Google::APIClient::JWTAsserter.new(
      CLIENT_EMAIL,
      'https://www.googleapis.com/auth/prediction',
      key)
  @client.authorization = asserter.authorize()

  @prediction = @client.discovered_api('prediction', 'v1.5')

end

def train
  training = @prediction.trainedmodels.insert.request_schema.new
  training.id = 'category_prediction_id'
  training.storage_data_location = DATA_OBJECT
  result = @client.execute(
      :api_method => @prediction.trainedmodels.insert,
      :headers => {'Content-Type' => 'application/json'},
      :body_object => training
  )

  return assemble_json_body(result)
end

def check_status
  result = @client.execute(
      :api_method => @prediction.trainedmodels.get,
      :parameters => {'id' => 'category_prediction_id'}
  )

  return assemble_json_body(result)
end

def predict(inpu)
  input = @prediction.trainedmodels.predict.request_schema.new
  input.input = {}
  input.input.csv_instance =  inpu
  result = @client.execute(
      :api_method => @prediction.trainedmodels.predict,
      :parameters => {'id' => 'category_prediction_id'},
      #:parameters => {'id' => 'act_type_id'},
      :headers => {'Content-Type' => 'application/json'},
      :body_object => input
  )

  return assemble_json_body(result)
end

def assemble_json_body(result)
  # Assemble some JSON our client-side code can work with.
  json = {}
  if result.status != 200
    if result.data["error"]
      message = result.data["error"]["errors"].first["message"]
      json["message"] = "#{message} [#{result.status}]"
    else
      json["message"] = "Error. [#{result.status}]"
    end
    json["response"] = ::JSON.parse(result.body)
    json["status"] = "error"
  else
    json["response"] = ::JSON.parse(result.body)
    json["status"] = "success"
  end
  return json
end
