require 'multi_json'
require 'realself/stream'

def activity(i)
  {
    "published" => "2013-08-13T16:36:59Z",
    "title" => "dr(57433) author answer(1050916) about question(1048591)",
    "actor" => 
    {
      "type" => "dr", 
      "id" => i.to_s
    },
    "verb" => "author",
    "object" => 
    {
      "type" => "answer",
      "id" => "1050916"
    },
    "target" => 
    {
      "type"=>"question", "id"=>"1048591"
    },
    "relatives" => 
    [
      {
        "type" => "topic",
        "id" => "265299"
      }
    ]
  }  
end

puts MultiJson.encode(activity(1))