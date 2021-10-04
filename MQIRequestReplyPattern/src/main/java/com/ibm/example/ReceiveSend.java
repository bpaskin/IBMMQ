package com.ibm.example;

import java.nio.charset.StandardCharsets;
import java.util.Hashtable;

import com.ibm.mq.MQException;
import com.ibm.mq.MQGetMessageOptions;
import com.ibm.mq.MQMessage;
import com.ibm.mq.MQPutMessageOptions;
import com.ibm.mq.MQQueue;
import com.ibm.mq.MQQueueManager;
import com.ibm.mq.constants.MQConstants;

public class ReceiveSend {
	static private String CHANNEL;
	static private int PORT;
	static private String HOST;
	static private String QMANAGER;
	static private MQQueueManager qMgr;
	
	public static void main(String[] args) {
		if (args.length != 4) {
			System.out.print("usage: java com.ibm.example.ReceiveSend host port channel qmgr");
			System.exit(1);
		}
		
		HOST = args[0];
		PORT = Integer.parseInt(args[1]);
		CHANNEL = args[2];
		QMANAGER = args[3];	
		
		while (true) {
			receiveSend();
		}
	}
	
	private static void connect(Hashtable<String, Object> props) {
		try {
			qMgr = new MQQueueManager(QMANAGER, props);
		} catch (Exception e) {
			e.printStackTrace(System.err);
			System.exit(1);
		}
	}
	
	private static void receiveSend() {
		Hashtable<String, Object> props = new Hashtable<String, Object>();
		props.put(MQConstants.CHANNEL_PROPERTY, CHANNEL);
		props.put(MQConstants.PORT_PROPERTY, PORT);
		props.put(MQConstants.HOST_NAME_PROPERTY, HOST);
		props.put(MQConstants.USER_ID_PROPERTY, "mqm");
		
		try {
			if (qMgr == null || !qMgr.isOpen()) {
				connect(props);
			}
			
			int openOptions = MQConstants.MQOO_INPUT_SHARED;
			MQQueue queue = qMgr.accessQueue("REQUEST.LQ", openOptions);
			MQGetMessageOptions gmo = new MQGetMessageOptions();
			gmo.options = MQConstants.MQGMO_COMPLETE_MSG | MQConstants.MQGMO_WAIT;
			MQMessage mqMessage = new MQMessage();
			gmo.waitInterval = -1;
			queue.get(mqMessage, gmo);
			String messagemq = mqMessage.readStringOfByteLength(mqMessage.getMessageLength());
			byte[] id = mqMessage.correlationId;
			String correlationId = new String(id, StandardCharsets.UTF_8);
			System.out.println("Recieved messages from QMGR " + mqMessage.replyToQueueManagerName + " with correlation id " + correlationId);
			System.out.println("message: " + messagemq);
			queue.close();
			
			openOptions = MQConstants.MQOO_OUTPUT;
			queue = qMgr.accessQueue(mqMessage.replyToQueueName, openOptions, mqMessage.replyToQueueManagerName, null, null);
			MQPutMessageOptions pmo = new MQPutMessageOptions();
			pmo = new MQPutMessageOptions();
			mqMessage = new MQMessage();
			mqMessage.correlationId = id;
			mqMessage.writeString("Thanks for sending your message");
			queue.put(mqMessage, pmo);
			queue.close();
			System.out.println("Response sent");
			
		} catch (MQException e) {
			if (e.reasonCode == 2033) {
				System.out.println("no message received");
			} else {
				e.printStackTrace(System.err);
			}
		} catch (Exception e) {
			e.printStackTrace(System.err);
		} 
	}
}
