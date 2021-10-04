package com.ibm.example;

import java.nio.charset.Charset;
import java.util.Hashtable;
import java.util.Random;

import com.ibm.mq.MQException;
import com.ibm.mq.MQGetMessageOptions;
import com.ibm.mq.MQMessage;
import com.ibm.mq.MQPutMessageOptions;
import com.ibm.mq.MQQueue;
import com.ibm.mq.MQQueueManager;
import com.ibm.mq.constants.MQConstants;

public class SendReceive {
	static private String CHANNEL;
	static private int PORT;
	static private String HOST;
	static private String QMANAGER;
	static private MQQueueManager qMgr;

	public static void main(String[] args) {

		if (args.length != 4) {
			System.out.print("usage: java com.ibm.example.SendReceive host port channel qmgr");
			System.exit(1);
		}
		
		HOST = args[0];
		PORT = Integer.parseInt(args[1]);
		CHANNEL = args[2];
		QMANAGER = args[3];		
		sendReceiveMessage();
	}
	
	private static void sendReceiveMessage() {
		Hashtable<String, Object> props = new Hashtable<String, Object>();
		props.put(MQConstants.CHANNEL_PROPERTY, CHANNEL);
		props.put(MQConstants.PORT_PROPERTY, PORT);
		props.put(MQConstants.HOST_NAME_PROPERTY, HOST);
		props.put(MQConstants.USER_ID_PROPERTY, "mqm");

		
		try {
			qMgr = new MQQueueManager(QMANAGER, props);
			int openOptions = MQConstants.MQOO_OUTPUT;
			MQQueue queue = qMgr.accessQueue("REQUEST", openOptions);
			MQPutMessageOptions pmo = new MQPutMessageOptions();
			MQMessage mqMessage = new MQMessage();
			mqMessage.replyToQueueName = "RESPONSE";
		    byte[] array = new byte[16]; 
		    new Random().nextBytes(array);
		    String id = new String(array, Charset.forName("UTF-8"));
			mqMessage.correlationId = id.getBytes();
			mqMessage.writeString("Hello from Sending App");
			queue.put(mqMessage, pmo);
			queue.close();
			System.out.println("Message was sent with correlation id: " + id);
			
			openOptions = MQConstants.MQOO_INPUT_SHARED;
			queue = qMgr.accessQueue("RESPONSE", openOptions);
			MQGetMessageOptions gmo = new MQGetMessageOptions();
			gmo.options = MQConstants.MQGMO_COMPLETE_MSG | MQConstants.MQGMO_WAIT;
			gmo.waitInterval = 30000;
			gmo.matchOptions = MQConstants.MQMO_MATCH_CORREL_ID;
			mqMessage.correlationId = id.getBytes();
			queue.get(mqMessage, gmo);
			String message = mqMessage.readStringOfByteLength(mqMessage.getMessageLength());
			System.out.println("recieved: " + message);
			queue.close();
			
		} catch (MQException e) {
			if (e.reasonCode == 2033) {
				System.out.println("no message returned");
			} else {
				e.printStackTrace(System.err);
			}
		} catch (Exception e) {
			e.printStackTrace(System.err);
		} finally {
			try {
				qMgr.disconnect();
			} catch (Exception e) {
			}
		}
	}
}
