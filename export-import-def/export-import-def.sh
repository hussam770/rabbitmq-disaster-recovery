# Requires management plugin to be enabled
curl -u guest:guest -X GET http://hussam-mint-linux:15672/api/definitions | jq > source-def.json

curl -u guest:guest -H "Content-Type: application/json" -X POST -T source-def.json hussam-mint-linux:15673/api/definitions