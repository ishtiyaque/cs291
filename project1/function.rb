# frozen_string_literal: true

require 'json'
require 'jwt'
require 'pp'

def main(event:, context:)
  # You shouldn't need to use context, but its fields are explained here:
  # https://docs.aws.amazon.com/lambda/latest/dg/ruby-context.html
  verb = event['httpMethod'].upcase
  path = event['path']
  
  if path != '/' and path != '/token'
    return response(body:nil,status: 404)
  end
  
  if (path == '/' and verb != 'GET') or (path == '/token' and verb != 'POST')
    return response(body:nil,status: 405)
  end
  
  if verb == 'POST'
    
    #if ((JSON.generate((event['headers']))).to_json)['content-type']) != 'application/json'
    event['headers'].each do |key, value|
      if key.downcase == 'content-type' and value != 'application/json'
        return response(body:nil,status: 415)
      end
    end
    
    requestBody = event['body']
    if requestBody == nil or requestBody == ''
      return response(body:nil, status: 422)
    end
    begin
      JSON.parse(requestBody)
      rescue JSON::ParserError => e
        return response(body:nil,status: 422)
    end
    
    payload = {
    data: requestBody,
    exp: Time.now.to_i + 5,
    nbf: Time.now.to_i + 2
    }
 
  
    token = JWT.encode( payload, ENV['JWT_SECRET'], 'HS256')
    return response(body: {
          'token' => token
      },status:201)
   
  end

  if verb == 'GET'
    found = false
    event['headers'].each do |key, value|
      if key.downcase == 'authorization'
          authBody = value.split(' ')
          break if authBody.count != 2
          break if authBody[0] != 'Bearer'
          token = authBody[1]
          decoded_token = ""
          begin
            decoded_token = JWT.decode token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' }
            rescue JWT::DecodeError => e
              return response(body:nil,status: 403)
          end
          found = true
          data = decoded_token[0]['data']
          return response(body:data.to_hash,status: 200)
        end
    end
    if found == false
      return response(body:nil,status: 403)
    end
  
  end

  response(body: event, status: 111)
end



def response(body: nil, status: 200)
  {
    body: body ? body.to_json + "\n" : '',
    statusCode: status
  }
end

if $PROGRAM_NAME == __FILE__
  # If you run this file directly via `ruby function.rb` the following code
  # will execute. You can use the code below to help you test your functions
  # without needing to deploy first.
  ENV['JWT_SECRET'] = 'NOTASECRET'

  # Call /token
  PP.pp main(context: {}, event: {
               'body' => '{"name": "bboe"}',
               'headers' => { 'Content-Type' => 'application/json' },
               'httpMethod' => 'POST',
               'path' => '/token'
             })

  # Generate a token
  payload = {
    data: { user_id: 128 },
    exp: Time.now.to_i + 1,
    nbf: Time.now.to_i
  }
  token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
  # Call /
  PP.pp main(context: {}, event: {
               'headers' => { 'Authorization' => "Bearer #{token}",
                              'Content-Type' => 'application/json' },
               'httpMethod' => 'GET',
               'path' => '/aaa'
             })
end
