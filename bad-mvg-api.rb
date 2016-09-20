require 'sinatra'
require 'net/http'
require 'JSON'
before do
    headers "Content-Type" => "text/json charset=utf8"
end

get '/stations' do
  res = send_request('StopAlso=true&ReturnList=stoppointname%2Cstopid%2Clatitude%2Clongitude%2Cstoppointstate')
  response = {version: 0.1, status: res.code};
  if(res.code != "200")
    return response.to_json
  end
  js = jsopnify(res.body)
  stations = [];
  return parse(js, response)

end

get "/station/:station_id" do
  res = send_request("StopAlso=false&ReturnList=visitnumber%2Clineid%2Clinename%2Cdirectionid%2Cdestinationtext%2Cdestinationname%2Cvehicleid%2Ctripid%2Cestimatedtime%2Cexpiretime&stopId=#{params[:station_id]}")
  response = {version: 0.1, status: res.code};
  if(res.code != "200")
    return response.to_json
  end
  js = jsopnify(res.body)
  st = parse(js, response)
  st[:raw] = js
  return st.to_json
end

get "/station/:station_id/messages" do
    res = send_request("StopAlso=false&ReturnList=messageuuid,messagepriority,messagetext,starttime,expiretime&stopId=#{params[:station_id]}")
    response = {version: 0.1, status: res.code};
    if(res.code != "200")
      return response.to_json
    end
    js = jsopnify(res.body)
    response = {version: 0.1, status: res.code};
    if(res.code != "200")
      return response.to_json
    end
    st = parse(js, response)
    return st.to_json
end
get "/trip/:trip_id" do
  res = send_request("StopAlso=false&ReturnList=stopid,stoppointname,latitude,longitude,visitnumber,vehicleid,estimatedtime,expiretime&TripId=#{params[:trip_id]}")
  response = {version: 0.1, status: res.code};
  if(res.code != "200")
    return response.to_json
  end
  js = jsopnify(res.body)
  st = parse(js, response)
  st[:raw] = js
  return st.to_json
end

def send_request(url)
    base = "http://ura.itcs.mvg-mainz.de/interfaces/ura/instant_V1?"
    uri = URI(base + url)
    http = Net::HTTP.new(uri.host, uri.port)
    req =  Net::HTTP::Get.new(uri)
    res = http.request(req)
    return res
end
def parseTrip(hash,response)
  trip_stops = []
  hash.each do |x|
    print x
    if x[0] == 4 then
      response[:api_version] = x[1]
      response[:timestamp] = x[2]
    end
    if x[0] == 1 then
      trip_stop = {}
    end
  end
end
def parse(hash,response)
  stations = [];
  lines = [];
  trip_stops = []
  someData = []
  messages = []
  hash.each do |x|
    print x
    if x[0] == 4 then
      response[:api_version] = x[1]
      response[:timestamp] = x[2]
    end
    if x[0] == 0 then
      station = {stationName: x[1],stationId: x[2],initState: x[3],latitude: x[4],longitude:x[5]}
      stations.push station
    end
    if x[0] == 1 then
      if x.length == 11 then
        line = {visitnumber: x[1], lineId: x[2], directionId: x[4], destinationName: x[5], tripid: x[8], estimatedtime: x[9],expiretime: x[10],  remainingMinutes:((x[9].to_i-response[:timestamp].to_i)/60000).to_i}
        lines.push line
      end
      if x.length == 9 then
        trip_stop = {stationName: x[1],stationId: x[2],latitude: x[3],longitude:x[4],visitnumber:[5],vehicleid:x[6], estimatedtime:x[7], expiretime:x[8],}
        stations.push trip_stop
      end
    end
    if x[0] == 2 then
      if x.length == 6 then
        message = {messageId: x[1], priority: x[2], message: x[3], starttime: x[4], endtime: x[5] }
        messages.push message
      else
        trip_stop = {stationName: x[1],stationId: x[2],latitude: x[3],longitude:x[4], estimatedtime: x[5], remainingMinutes:(x[5].to_i/60000).to_i}
        someData.push trip_stop
      end

    end
  end
  unless stations.length == 0
    response[:stations] = stations
  end
  unless lines.length == 0
    trip_stops.sort_by  {|trip| trip[:visitnumber]}
    response[:lines] = lines
  end
  unless trip_stops.length == 0
    trip_stops.sort_by  {|trip| trip[:visitnumber]}
    response[:stops] = trip_stops
  end
  unless someData.length == 0
    response[:someData] = someData
  end
  unless messages.length == 0
    response[:messages] = messages
  end
  return response
end

def jsonify(body)
  body = "["+body+"]"
  body.gsub!("\r\n", ",")
  return JSON.parse(body)
end
