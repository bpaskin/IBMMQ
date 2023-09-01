#!/bin/bash
# parse MQI Stats
# (amqsmon -m <qmanager> -t statistics -a)
#
# Brian S Paskin
# 31/8/2023 v1.0.0

# current directory
CURRDIR=`pwd`

# Check the number of args passed, it should be 1 for the file name
if [ $# -ne 1 ]; then
	echo "usage: parseMQI.sh file"
	exit 1
fi

FILENAME=$1

# check if file exists

if [ ! -f $FILENAME ]; then
	echo "File $FILENAME does not exist or is unreadable"
	exit 2
fi

# create results dir if necessary
OUTDIR=`pwd`/outputMQI

if [ ! -f $OUTDIR ]; then
	mkdir -p $OUTDIR

	if [ $? -ne 0 ]; then
		echo "Failed to create directory $OUTDIR"
		exit 3
	fi
fi

# Get the number of records based on the MQI Stats
NUM_RECS=`grep "MQIStatistics" $FILENAME | wc -l`

if [ $NUM_RECS -eq 0 ]; then
	echo "The file $FILENAME does not contain any NQI Statistics"
	exit 4
fi

# Get the QMGR name, used for the filename too
QMGR=`grep "QueueManager" $FILENAME | head -1 | cut -d ":" -f 2 | cut -d "'" -f 2`

echo "QMGR: $QMGR"
echo "Number of records: $NUM_RECS"

OUT_FILE=$OUTDIR/$QMGR.csv

# create file headers
echo "Connections, Max Concurrent Connections, Open Queue, Open QMGR, Open Channel, Open Topic, Put Count (total), Put Bytes (total), Get Count (total), Get Bytes (total), Subscriptions (total), Put Topic (total), Put Topic Bytes (total), Publish Msg Count (total), Publish Msg Bytes (total)" > $OUT_FILE

DONE=0
COUNT=0
# Loop through file
while read -r LINE; do

	# Total number of connections
	if [[ "$LINE" == *"ConnCount"* ]]; then
		CONNS=`echo $LINE |  cut -d ":" -f 2 | xargs`
	fi

	# Maxium number of connections at given interval
	if [[ "$LINE" == *"ConnHighwater"* ]]; then
		MAX_CONN=`echo $LINE |  cut -d ":" -f 2 | xargs`
	fi

	# Open Counts
	if [[ "$LINE" == *"OpenCount"* ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs`
		OPEN_Q=`echo $STATS |  cut -d "," -f 2 | xargs`
		OPEN_QMGR=`echo $STATS |  cut -d "," -f 6 | xargs`
		OPEN_CHL=`echo $STATS |  cut -d "," -f 7 | xargs`
		OPEN_TOPIC=`echo $STATS |  cut -d "," -f 9 | xargs`
	fi

	# Put Count
	if [[ "$LINE" == *"PutCount"* ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs | sed 's/^.//' | sed 's/.$//'`
		PUT_NONPERSIST=`echo $STATS |  cut -d "," -f 1 | xargs`
		PUT_PERSIST=`echo $STATS |  cut -d "," -f 2 | xargs`
	fi

	if [[ "$LINE" == *"Put1Count"* ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs | sed 's/^.//' | sed 's/.$//'`
		PUT1_NONPERSIST=`echo $STATS |  cut -d "," -f 1 | xargs`
		PUT1_PERSIST=`echo $STATS |  cut -d "," -f 2 | xargs`
	fi

	TOT_PUT=$((PUT_NONPERSIST + PUT_PERSIST + PUT1_NONPERSIST + PUT1_PERSIST))

	# Put Bytes
		if [[ "$LINE" == *"PutBytes"* ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs | sed 's/^.//' | sed 's/.$//'`
		PUT_BYTES_NONPERSIST=`echo $STATS |  cut -d "," -f 1 | xargs`
		PUT_BYTES_PERSIST=`echo $STATS |  cut -d "," -f 2 | xargs`
	fi

	TOT_PUT_BYTES=$((PUT_BYTES_NONPERSIST + PUT_BYTES_PERSIST))

	# Get Count
	if [[ "$LINE" == *"GetCount"* ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs | sed 's/^.//' | sed 's/.$//'`
		GET_NONPERSIST=`echo $STATS |  cut -d "," -f 1 | xargs`
		GET_PERSIST=`echo $STATS |  cut -d "," -f 2 | xargs`
	fi

	TOT_GET=$((GET_NONPERSIST + GET_PERSIST))

	# Get Bytes
	if [[ "$LINE" == *"GetBytes"* ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs | sed 's/^.//' | sed 's/.$//'`
		GET_BYTES_NONPERSIST=`echo $STATS |  cut -d "," -f 1 | xargs`
		GET_BYTES_PERSIST=`echo $STATS |  cut -d "," -f 2 | xargs`
	fi

	TOT_GET_BYTES=$((GET_BYTES_NONPERSIST + GET_BYTES_PERSIST))

	# Get subscriptions counts
	if [[ `echo $LINE |  cut -d ":" -f 1 | xargs` == "DurableSubscribeCount" ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs | sed 's/^.//' | sed 's/.$//'`
		TOT_DUR_SUB=`echo $STATS |  cut -d "," -f 1 | xargs`
	fi

	if [[ `echo $LINE |  cut -d ":" -f 1 | xargs` == "NonDurableSubscribeCount" ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs | sed 's/^.//' | sed 's/.$//'`
		TOT_NONDUR_SUB=`echo $STATS |  cut -d "," -f 1 | xargs`
	fi

	TOT_SUB=$((TOT_DUR_SUB + TOT_NONDUR_SUB))

	# Num of Put on Topic
	if [[ "$LINE" == *"PutTopicCount"* ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs | sed 's/^.//' | sed 's/.$//'`
		TOPIC_PUT_NONPERSIST=`echo $STATS |  cut -d "," -f 1 | xargs`
		TOPIC_PUT_PERSIST=`echo $STATS |  cut -d "," -f 2 | xargs`
	fi

	if [[ "$LINE" == *"Put1TopicCount"* ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs | sed 's/^.//' | sed 's/.$//'`
		TOPIC_PUT1_NONPERSIST=`echo $STATS |  cut -d "," -f 1 | xargs`
		TOPIC_PUT1_PERSIST=`echo $STATS |  cut -d "," -f 2 | xargs`
	fi

	TOT_PUT_TOPIC=$((TOPIC_PUT_NONPERSIST + TOPIC_PUT_PERSIST + TOPIC_PUT1_NONPERSIST + TOPIC_PUT1_PERSIST))

	# Put Topic Totals Bytes
		if [[ "$LINE" == *"PutTopicBytes"* ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs | sed 's/^.//' | sed 's/.$//'`
		TOPIC_PUT_BYTES_NONPERSIST=`echo $STATS |  cut -d "," -f 1 | xargs`
		TOPIC_PUT_BYTES_PERSIST=`echo $STATS |  cut -d "," -f 2 | xargs`
	fi

	TOT_TOPIC_PUT_BYTES=$((TOPIC_PUT_BYTES_PERSIST + TOPIC_PUT_BYTES_NONPERSIST))

	# Publish Msg count
	if [[ "$LINE" == *"PublishMsgCount"* ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs | sed 's/^.//' | sed 's/.$//'`
		PUB_MSG_COUNT_NONPERSIST=`echo $STATS |  cut -d "," -f 1 | xargs`
		PUB_MSG_COUNT_PERSIST=`echo $STATS |  cut -d "," -f 2 | xargs`
	fi

	TOT_PUB_MSG_COUNT=$((PUB_MSG_COUNT_PERSIST + PUB_MSG_COUNT_NONPERSIST))

	# Publish Msg bytes
	if [[ "$LINE" == *"PublishMsgBytes"* ]]; then
		STATS=`echo $LINE |  cut -d ":" -f 2 | xargs | sed 's/^.//' | sed 's/.$//'`
		PUB_MSG_BYTES_NONPERSIST=`echo $STATS |  cut -d "," -f 1 | xargs`
		PUB_MSG_BYTES_PERSIST=`echo $STATS |  cut -d "," -f 2 | xargs`
		DONE=1
	fi

	TOT_PUB_MSG_BYTES=$((PUB_MSG_BYTES_PERSIST + PUB_MSG_BYTES_NONPERSIST))


	if [[ $DONE = 1 ]]; then
		echo "$CONNS,$MAX_CONN,$OPEN_Q,$OPEN_QMGR,$OPEN_CHL,$OPEN_TOPIC,$TOT_PUT,$TOT_PUT_BYTES,$TOT_GET,$TOT_GET_BYTES,$TOT_SUB,$TOT_PUT_TOPIC,$TOT_TOPIC_PUT_BYTES,$TOT_PUB_MSG_COUNT,$TOT_PUB_MSG_BYTES" >> $OUT_FILE
		COUNT=$((COUNT + 1))
		if (( COUNT % 50 == 0 )); then
			echo "processed $COUNT records"
		fi
		DONE=0
	fi

done < $FILENAME

echo "processed $COUNT records"