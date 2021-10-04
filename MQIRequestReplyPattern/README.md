This is a sample of using the Request-Reply pattern using IBM MQ. There are two single instance QMGRs, `QM1HACK` and `QM2HACK`, and they are connected using SDR and RCVR channels.  `QM1HACK` has a remote queue, `REQUEST`, and a local queue, called `RESPONSE`.  The remote queue points to a local queue on `QM2HACK`, called `REQUEST.LQ`.  

Why isolate the QMGRs?  For security purposes.  In a cluster other QMGRs can possbily update or retrieve data from others that are not intended to have access.  

The idea is that a sending program sends a message to `QM1HACK` queue `REQUEST` with certain information in the header, like which queue and QMGR to respond, and forwards the data to the appropriate queue, `REQUEST.LQ`, on `QM2HACK`.  The receiving program takes the header information and sends it to `QM2HACK`. which takes the information and forwards the information to appropriate QMGR and queueu, in this case, `RESPONSE` queue on the `QM1HACK` QMGR.  This is done without defining anything about the queue on `QM2HACK`.  This is a feature of IBM MQ.

The two programs `com.ibm.example.ReceiveSend` and `com.ibm.example.SendReceive` can be used to test the QMGRs and Queues.  The `ReceiveSend` application will wait until a message appears on the `RESPONSE.LQ` on `QM2HACK` and respond to `QM2HACK` with the QMGR sent in the header along with the correlation id.  The `SendReceive` application will send a message to `QM1HACK` on the `REQUEST` queue and wait for a response for 30 seconds on the `RESPONSE` queue using the correlation id.

Usage:

`java com.ibm.example.ReceiveSend host port channel qmgr`

`java com.ibm.example.SendReceive host port channel qmgr`

The MQSC files for the QMGRs are included.  The `conname` should be changed to the system where the QMGRs are running.  The scripted `setup.sh` will create the QMGRs, start the QMGRS, and import the definitions.
