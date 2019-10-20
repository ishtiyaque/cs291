require 'sinatra'
require "google/cloud/storage"
require 'json'
require 'digest'


require 'pp'

$storage = Google::Cloud::Storage.new(project_id: 'cs291-f19')
$bucket = $storage.bucket 'cs291_project2', skip_lookup: true




get '/' do
  status 302
  redirect to('/files/')
end

get '/files/:digest' do
  digest = params['digest'].downcase
  if digest.length != 64 or !!digest[/\H/]
    status 422
    return
  end
  filename = digest.insert(2,'/')
  filename = filename.insert(5,'/')
  file = $bucket.file filename
  if file == nil
    status 404
    return
  end
  headers "Content-Type" => file.content_type, "Content-Length" => file.size

  content = file.download
  #send_file content

end

get '/files/' do
  status 200
  #storage = Google::Cloud::Storage.new(project_id: 'cs291-f19')
  #bucket = storage.bucket 'cs291_project2', skip_lookup: true
  all_files = $bucket.files
  #puts all_files.class
  file_names = Array.new
  all_files.each do |file|
    name = file.name
    if name[2] == "/" and name[5] == "/" 
      #digest = name[0,2] + name[3,2] + name[6..-1]
      digest = name.tr('/','')
      if digest.length == 64 and !digest[/\H/]
        file_names.push(digest)
      end
    end
  end
  #JSON.parse(file_names)
  headers "Content-Type" => "application/json"
  file_names.sort.to_json
end

delete '/files/:digest' do
  digest = params['digest'].downcase
  if digest.length != 64 or !!digest[/\H/]
    status 422
    return
  end
  status 200
  filename = digest.insert(2,'/')
  filename = filename.insert(5,'/')
  file = $bucket.file filename
  if file == nil
    return
  end
  file.delete
end

post '/files/' do
  max_file_size = 1024 * 1024
    
  if params == nil or params[:file] == nil or params[:file].class == String
    #puts params[:file].class
    status 422
    return
  end
  #p params
  file = params[:file][:tempfile]
  if file == nil
    status 422
    return
  end

  #file = File.open(filename)
  if file.size > max_file_size
    status 422
    return
  end
  
  content = file.read
  
  digest = Digest::SHA256.hexdigest content
  mod_digest = digest.dup
  mod_digest = mod_digest.insert(2,"/")
  mod_digest = mod_digest.insert(5,"/")
  
  if $bucket.file(mod_digest) != nil  
    status 409
    return
  end  
  content_type = params[:file][:type]
  #puts "content_type is : #{content_type}"
  $bucket.create_file(file, path=mod_digest, content_type:content_type)
        
  #file.close
  status 201
  {:uploaded => digest}.to_json
end
