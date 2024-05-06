#!/usr/bin/env bash
# Requires management plugin to be enabled
# Lunix Java 17+ 
# Lunix jq
# Curl 


# Example 
# ./pull-rabbitmq-queues.sh -s hussam-mint-linux -sp 15672:5672 -d hussam-mint-linux:5673 -dp 15672:5672


defintion_file="source-def.json"

#STS : server to server - default 
#STF : server to filesystem
#FTS : filesystem to server 
direction="STS"
source=""
destination=""
sourceports=""
destinationports=""
sourceauth=""
destinationauth=""

readonly script_name="${0##*/}"

die() {
    local -r msg="${1}"
    local -r code="${2:-90}"
    echo "${msg}" >&2
    exit "${code}"
}
#./pull-rabbitmq-queues.sh -s hussam-mint-linux --sport 15672:5672 --sauth guest:guest -d hussam-mint-linux --dport 15673:5673 --dauth guest:guest


usage() {
    cat <<USAGE_TEXT
Usage: ${script_name} [-h] [-s <ARG> --sport <ARG> --sauth <ARG> -d <ARG> --dport <ARG> --dauth <ARG>]

DESCRIPTION
    RabbitMQ utility to move messages from source rabbitMQ server to a destnation server 

    OPTIONS:

    -s
        Source AMQP server .

    -d
        Destination AMQP server.

    --sport
        Source AMQP server ports e.g 15672:5672.

    --dport
        Destinatioin AMQP server ports e.g 15672:5672.

    --sauth
        Source AMQP server username:password.

    --dauth
        Destinatioin AMQP server username:password.

    AUTHERS:
       Hussam abu-libdeh

USAGE_TEXT
}

for arg in "$@"; do
  shift
  case "$arg" in
  	'-s')   set -- "$@" '-s'   ;;
  	'-d')   set -- "$@" '-d'   ;;
	'-h')   set -- "$@" '-h'   ;;
	'-r')   set -- "$@" '-r'   ;;
    '--sport')   set -- "$@" '-p'   ;;
    '--dport') set -- "$@" '-t'   ;;
    '--sauth')   set -- "$@" '-u'   ;;
    '--dauth')     set -- "$@" '-k'   ;;
	*)          set -- "$@" "$arg" ;;
  esac
done

OPTSTRING=":s:d:p:t:u:k:hr"

while getopts ${OPTSTRING} opt; do
  case "${opt}" in
    s)
      source="${OPTARG}"
      ;;
    d)
      destination="${OPTARG}"
      ;;
	p)
      sourceports="${OPTARG}"
      ;;
	t)
      destinationports="${OPTARG}"
      ;;
	u)
      sourceauth="${OPTARG}"
      ;;
	k)
      destinationauth="${OPTARG}"
      ;;
	h)
      usage
      die "error: parsing options" 1
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
	  echo "Invalid option usage , type -h for help."
	  exit 1
      ;;
    ?)
      echo "Invalid option usage , type -h for help."
      exit 1
      ;;
  esac
done

invalid_flag=0

if [ -z "${source}" ]; then
    invalid_flag=1
    echo "Missing source hostname, specify it with -h parameter"
fi

if [ -z "${destination}" ]; then
    invalid_flag=1
    echo "Missing destination hostname, specify it with -h parameter"
fi

if [ -z "${sourceports}" ]; then
    invalid_flag=1
    echo "Missing source ports, specify it with -h parameter"
fi

if [ -z "${destinationports}" ]; then
    invalid_flag=1
    echo "Missing destination ports, specify it with -h parameter"
fi

if [ -z "${sourceauth}" ]; then
    invalid_flag=1
    echo "Missing source authentication values, specify it with -h parameter"
fi

if [ -z "${destinationauth}" ]; then
    invalid_flag=1
    echo "Missing destination authentication values, specify it with -h parameter"
fi

if ((invalid_flag)); then
    die "Cannot proceed with missing required parameters." 1
fi



http_source_port=$(cut -d : -f 1 <<< ${sourceports})
AMQP_source_port=$(cut -d : -f 2 <<< ${sourceports})

http_dest_port=$(cut -d : -f 1 <<< ${destinationports})
AMQP_dest_port=$(cut -d : -f 2 <<< ${destinationports})

if [ "$source $sourceports" = "$destination $destinationports" ]; then
    die "The source and destination server are the same (${source}:$sourceports -> ${destination}:$destinationports)." 1
fi

echo "direction is ${direction} ..."

curl -u ${sourceauth} -X GET http://${source}:${http_source_port}/api/definitions | jq > ${defintion_file}

curl -u ${destinationauth} -H "Content-Type: application/json" -X POST -T ${defintion_file} ${destination}:${http_dest_port}/api/definitions

while read -r val ; do
	queuename=$( jq -r '.name' <<< ${val})
	vhname=/$( jq -r '.vhost' <<< ${val})
	if [ "$vhname" == "//" ]; then
		echo "default virtual host.."	
		unset vhname
	fi
	echo "Moving queue messeges : ${queuename}, exists in virtual host : ${vhname} to the specified destination"
	java -jar k-rabbitmq-cdr.jar --source-type AMQP --source-uri amqp://${sourceauth}@${source}:${AMQP_source_port}${vhname} --source-queue "${queuename}" --target-type AMQP --target-uri amqp://${destinationauth}@${destination}:${AMQP_dest_port}${vhname} --target-queue "${queuename}"
	echo "Moving to queue ${queuename} finished ..."
done < <(jq -rc '.queues[]' ${defintion_file})


#./pull-rabbitmq-queues.sh -s hussam-mint-linux --sport 15672:5672 --sauth guest:guest -d hussam-mint-linux --dport 15673:5673 --dauth guest:guest





