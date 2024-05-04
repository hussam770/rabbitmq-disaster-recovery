#!/usr/bin/env bash
# Requires management plugin to be enabled
# Lunix Java 17+ 
# Lunix jq
# Curl 


# Example 
# ./pull-rabbitmq-queues.sh -s hussam-mint-linux -sp 15672:5672 -d hussam-mint-linux:5673 -dp 15672:5672

source=""
destination=""
defintion_file="source-def.json"

#STS : server to server - default 
#STF : server to filesystem
#FTS : filesystem to server 
direction="STS"
sports=""
dports=""

die() {
    local -r msg="${1}"
    local -r code="${2:-90}"
    echo "${msg}" >&2
    exit "${code}"
}

OPTSTRING=":s:d:p:t:r"

while getopts ${OPTSTRING} opt; do
  case "${opt}" in
    s)
      source="${OPTARG}"
      ;;
    d)
      destination="${OPTARG}"
      ;;
	--sports)
      p="${OPTARG}"
      ;;
	t)
    --dports="${OPTARG}"
      ;;
	r)
	  if [ "${OPTARG}" = "STS" ] || [ "${OPTARG}" = "STF" ] || [ "${OPTARG}" = "FTS" ]
	  then 
	  	direction="${OPTARG}"
	  else 
	  	echo "Invalid option: -${OPTARG}. , direction must be one of the following STS , STF , FTS"
      	exit 1
	  fi
      ;;
    :)
      echo "Option -${OPTARG} requires an argument."
      exit 1
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 1
      ;;
  esac
done

http_source_port=$(cut -d : -f 1 <<< ${sports})
AMQP_source_port=$(cut -d : -f 2 <<< ${sports})

http_dest_port=$(cut -d : -f 1 <<< ${dports})
AMQP_dest_port=$(cut -d : -f 2 <<< ${dports})

if [ "$source $p" = "$destination $t" ]; then
    die "The source and destination server are the same (${source}:$p -> ${destination}:$t)." 1
fi

echo "direction is ${direction} ..."

curl -u guest:guest -X GET http://${source}:${http_source_port}/api/definitions | jq > ${defintion_file}

curl -u guest:guest -H "Content-Type: application/json" -X POST -T ${defintion_file} ${destination}:${http_dest_port}/api/definitions

while read -r val ; do
	queuename=$( jq -r '.name' <<< ${val})
	vhname=/$( jq -r '.vhost' <<< ${val})
	if [ "$vhname" == "//" ]; then
		echo "default virtual host.."	
		unset vhname
	fi
	echo "Moving queue messeges : ${queuename}, exists in virtual host : ${vhname} to the specified destination"
	java -jar k-rabbitmq-cdr.jar --source-type AMQP --source-uri amqp://guest:guest@${source}:${AMQP_source_port}${vhname} --source-queue "${queuename}" --target-type AMQP --target-uri amqp://guest:guest@${destination}:${AMQP_dest_port}${vhname} --target-queue "${queuename}"
	echo "Moving to queue ${queuename} finished ..."
done < <(jq -rc '.queues[]' ${defintion_file})



