# Requires management plugin to be enabled
curl -u guest:guest -X GET http://hussam-mint-linux:15672/api/definitions | jq > source-def.json

curl -u guest:guest -H "Content-Type: application/json" -X POST -T source-def.json hussam-mint-linux:15673/api/definitions

while read -r val ; do
	queuename=$( jq -r '.name' <<< ${val})
	vhname=/$( jq -r '.vhost' <<< ${val})
	if [ "$vhname" == "//" ]; then
		echo "empty virtual host"	
		unset vhname
	fi
	echo "Moving queue messeges : ${queuename}, exists in virtual host : ${vhname} to the specified destination"
	java -jar ../k-rabbitmq-cdr.jar --source-type AMQP --source-uri amqp://guest:guest@localhost:5672${vhname} --source-queue "${queuename}" --target-type AMQP --target-uri amqp://guest:guest@localhost:5673${vhname} --target-queue "${queuename}"
	echo "Moving to queue ${queuename} finished ..."
done < <(jq -rc '.queues[]' source-def.json)

