#/bin/bash 

url="localhost:8080"
dir=$(date "+%y%m%d-%H-%M")
mkdir $dir
curl $url/stations > $dir/stations.json
for station in $(cat $dir/stations.json | jq '.stations[] | .stationId' -r ); do
    curl $url/station/$station > $dir/station_$station.json
done

for station in $(ls $dir/station_*); do
    echo "Station $station"
    trips=$(cat $station | jq '.lines[] | .tripid')
    if [[ $? == 0 ]]; then
        for trip in $(cat $station | jq '.lines[] | .tripid'); do
            curl $url/trip/$trip > $dir/trip_$trip.json
        done
    fi
done




