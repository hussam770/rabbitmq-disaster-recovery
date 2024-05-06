java -jar k-rabbitmq-cdr.jar --source-type AMQP --source-uri amqp://guest:guest@localhost:5672/vh1 --source-queue source --target-type AMQP --target-uri amqp://guest:guest@localhost:5673/vh2 --target-queue dest
./pull-rabbitmq-queues-messsages.sh -s hussam-mint-linux --sport 15672:5672 --sauth guest:guest -d hussam-mint-linux --dport 15673:5673 --dauth guest:guest
./pull-rabbitmq-queues-messsages.sh -r STF -s hussam-mint-linux --sport 15672:5672 --sauth guest:guest -f "../payloads"
./pull-rabbitmq-queues-messsages.sh -r FTS -f "../payloads" -d hussam-mint-linux --dport 15673:5673 --dauth guest:guest
./pull-rabbitmq-queues-messsages.sh -r PURGE -d hussam-mint-linux --dport 15673:5673 --dauth guest:guest