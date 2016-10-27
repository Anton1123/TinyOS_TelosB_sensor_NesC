#include <UserButton.h>
#include <stdlib.h>
#include "Sender.h"

#define LOSSLEVEL 50
#define LOSSLEVELNP 50

module SenderC {
	uses { //General Interface
		interface Boot;
		interface Timer<TMilli>;
	}
	
	uses { //Radio
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface SplitControl as AMControl;
		interface Receive;	
	}
}

implementation {	
	bool _radioBusy = FALSE;
	message_t _packet;
	uint16_t packetID = 1;
	uint16_t jcounter = 0;
	list priority;
	list nonPriority;
	sample curr_sample;
	uint16_t i;
	uint16_t curr_listSize;
	int16_t r;
	uint16_t PPsent = 0;
	uint16_t NPsent = 0;
	uint16_t PPattempted = 0;
	uint16_t NPattempted = 0;
	uint16_t PPreattempted = 0;
	uint16_t PPresent = 0;

	event void Boot.booted() {
		call AMControl.start();
		printf("*********************************\r\n");
		printf("Starting transmission...\r\n");
		printf("*********************************\r\n");
		
		// Seed the random function using the light sensor reading
		// init of global variables
		prevprev = prev;
		prev = current;
		current = next;
		next = nextnext;
		nextnext = jogdatax[jcounter];

		++jcounter;
		call Timer.startPeriodic(10);
	}

	event void Timer.fired() {
		r = rand();
		if (r < 0)
			r = r*(-1);
		if(jcounter > SIZE + 1) { 
			// Reached the end of hard-coded sample data
			MoteToMoteMsg_t* msg = call Packet.getPayload(& _packet, sizeof(MoteToMoteMsg_t));
			msg -> msgID = packetID++;
			msg -> tag = 1;
			// start by sending the rest of the data in the priority queue
			if(listSize(priority) < 5 && listSize(priority) > 0) {
				// less than 5 readings in the priority queue
				curr_listSize = listSize(priority);
				for(i = 0; i < curr_listSize; ++i) {
					curr_sample = priority.front->item;
					priority = deleteFront(priority);
					msg->lumArray[i] = curr_sample.data;
					msg->mapArray[i] = curr_sample.id;	
				}
				//fill in the rest of the packet with 0's'
				for(i = curr_listSize; i < 5; ++i) {
					msg->lumArray[i] = 0;
					msg->mapArray[i] = 0;	
				}
				Enqueue(*msg); //priority packet going into the packet buffer to wait for ACK 
				PPattempted++;
				if(r % 100 > LOSSLEVEL) {
					//Sending the Packet
					PPsent++;
					if (call AMSend.send(AM_BROADCAST_ADDR, & _packet, sizeof(MoteToMoteMsg_t)) == SUCCESS){
						printf("Sending the last priority packet with ID# %d\r\n", packetID - 1);
						_radioBusy = TRUE;
						printf("Sample values sent:\r\n");
						for(i = 0; i < 5; i++) {
							printf("%d (#%d) ", msg->lumArray[i],  msg->mapArray[i]);
						}
						printf("\r\n\n");	
					}
					else {
						printf("(1)Transmission failed...\r\n");
					}
				}
				// no more samples in the priority queue
			}
			//if 5 or more readings are in the priority queue
			else if(listSize(priority) >= 5) {
				for(i = 0; i < 5; ++i) {
					curr_sample = priority.front->item;
					priority = deleteFront(priority);
					msg->lumArray[i] = curr_sample.data;
					msg->mapArray[i] = curr_sample.id;
				}
				Enqueue(*msg); //priority packet going into the packet buffer to wait for ACK 
				PPattempted++;
				if(r % 100 > LOSSLEVEL) {
					//Sending the Packet
					PPsent++;
					if (call AMSend.send(AM_BROADCAST_ADDR, & _packet, sizeof(MoteToMoteMsg_t)) == SUCCESS){
						printf("Sending a priority packet with ID# %d\r\n", packetID - 1);
						_radioBusy = TRUE;
						printf("Sample values sent:\r\n");				
						for(i = 0; i < 5; i++) {
							printf("%d (#%d) ", msg->lumArray[i],  msg->mapArray[i]);
						}
						printf("\r\n\n");
					}
					else {
						printf("(2)Transmission failed.\r\n");
					}
				}
			}
			// sending everything in the packet buffer queue that we haven't received an ACK for
			else if(queue_size > 0) {
				*msg = Front(); 
				Dequeue(msg->msgID);
				PPreattempted++;
				if(r % 100 > LOSSLEVEL) {
					//Sending the Packet
					PPresent++;
					if (call AMSend.send(AM_BROADCAST_ADDR, & _packet, sizeof(MoteToMoteMsg_t)) == SUCCESS){
						printf("Resending packet with ID %d...\r\n\n", msg -> msgID);
						_radioBusy = TRUE;
					}	
					else {
						printf("(3)Transmission failed.\r\n");
					}
				}
			}
			// non-priority queue has less than 5 samples
			else if(listSize(nonPriority) < 5 && listSize(nonPriority) > 0) {
				msg -> tag = 0; //update tag to non-priority
				curr_listSize = listSize(nonPriority);
				for(i = 0; i < curr_listSize; i++) {
					curr_sample = nonPriority.front->item;
					nonPriority = deleteFront(nonPriority);
					msg->lumArray[i] = curr_sample.data;
					msg->mapArray[i] = curr_sample.id;	
				}
				//fill in the rest of the packet with 0's'
				for(i = curr_listSize; i < 5; ++i) {
					msg->lumArray[i] = 0;
					msg->mapArray[i] = 0;	
				}
				NPattempted++;
				if(r % 100 > LOSSLEVELNP) {
					//Sending the Packet
					NPsent++;
					if (call AMSend.send(AM_BROADCAST_ADDR, & _packet, sizeof(MoteToMoteMsg_t)) == SUCCESS){
						printf("Sending the last non-priority packet with ID# %d\r\n", packetID - 1);
						_radioBusy = TRUE;
						printf("Sample values sent:\r\n");
						for(i = 0; i < 5; i++) {
							printf("%d (#%d) ", msg->lumArray[i],  msg->mapArray[i]);
						}
						printf("\r\n\n");	
					}				
					else {
						printf("(4)Transmission failed.\r\n");
					}
				}
				
				if (listSize(nonPriority) == 0) {
					//no more samples in the non-priority queue
					printf("End of transmission. All %d data readings sent.\r\n", jcounter - 2);
					printf("Priority packets attepted to send: %d\r\n", PPattempted);
					printf("Priority packets actually sent with %d loss: %d\r\n", LOSSLEVEL, PPsent);
					printf("Non-Priority packets attepted to send: %d\r\n", NPattempted);
					printf("Non-Priority packets actually sent with %d loss: %d\r\n", LOSSLEVELNP, NPsent);
					printf("Priority packets re-attepted to send: %d\r\n", PPreattempted);
					printf("Priority packets actually re-sent with %d loss: %d\r\n", LOSSLEVEL, PPresent);
					call Timer.stop();
				}
				
			}
			//if 5 or more readings are in the non-priority queue
			else if(listSize(nonPriority) >= 5) {
				msg -> tag = 0;
				for(i = 0; i < 5; ++i) {
					curr_sample = nonPriority.front->item;
					nonPriority = deleteFront(nonPriority);
					msg->lumArray[i] = curr_sample.data;
					msg->mapArray[i] = curr_sample.id;
				}
				NPattempted++;
				if(r % 100 > LOSSLEVELNP) {	
					//Sending the Packet
					NPsent++;
					if (call AMSend.send(AM_BROADCAST_ADDR, & _packet, sizeof(MoteToMoteMsg_t)) == SUCCESS){
						printf("Sending a non-priority packet with ID# %d\r\n", packetID - 1);
						_radioBusy = TRUE;
						printf("Sample values sent:\r\n");
						for(i = 0; i < 5; i++) {
							printf("%d (#%d) ", msg->lumArray[i],  msg->mapArray[i]);
						}
						printf("\r\n\n");
					}
					else {
						printf("(5)Transmission failed.\r\n");
					}
				}
				
				if (listSize(nonPriority) == 0) {
					//no more samples in the non-priority queue
					printf("End of transmission. All %d data readings sent.\r\n", jcounter - 2);
					printf("Priority packets attepted to send: %d\r\n", PPattempted);
					printf("Priority packets actually sent with %d loss: %d\r\n", LOSSLEVEL, PPsent);
					printf("Non-Priority packets attepted to send: %d\r\n", NPattempted);
					printf("Non-Priority packets actually sent with %d loss: %d\r\n", LOSSLEVELNP, NPsent);
					printf("Priority packets re-attepted to send: %d\r\n", PPreattempted);
					printf("Priority packets actually re-sent with %d loss: %d\r\n", LOSSLEVEL, PPresent);
					call Timer.stop();
				}
			}
		}
		else if(jcounter % 5 == 0) {
			// reached 5 more readings, possibility of all 5 being priority
			// could change the 5 to something smaller or bigger depending on how often we want to check the queues for the creation and sending of packets
			if(front == NULL) { 
				//if empty buffer queue, we proceed with checking the priority and non-priority queues
				if(listSize(priority) >= 5) {
					//we have at least 5 readings in the priority queue
					//creating the packet of the first 5 items in the priority queue
					//repeat until priority queue is empty (change 'if' to 'while' to send all the samples at this time in the priority queue)
					MoteToMoteMsg_t* msg = call Packet.getPayload(& _packet, sizeof(MoteToMoteMsg_t)); 
					msg -> msgID = packetID++;
					msg -> tag = 1;
					for(i = 0; i < 5; ++i) {
						curr_sample = priority.front->item;
						priority = deleteFront(priority);
						msg->lumArray[i] = curr_sample.data;
						msg->mapArray[i] = curr_sample.id;
					}
					Enqueue(*msg); //priority packet going into the packet buffer to wait for ACK 
					PPattempted++;
					if(r % 100 > LOSSLEVEL) {
						//Sending the Packet
						PPsent++;
						if (call AMSend.send(AM_BROADCAST_ADDR, & _packet, sizeof(MoteToMoteMsg_t)) == SUCCESS){
							printf("Sending a priority packet with ID# %d.\r\n", packetID - 1);
							_radioBusy = TRUE;
							printf("Sample values sent:\r\n");
							for(i = 0; i < 5; i++) {
								printf("%d (#%d) ", msg->lumArray[i],  msg->mapArray[i]);
							}
						}
						else {
							printf("(6)Transmission failed.\r\n");			
						}
					}
					printf("\r\n\n");
				}
				else if(listSize(nonPriority) >= 5) {
					//we don't have at least 5 readings in the priority queue but have at least 5 in the non-priority
					MoteToMoteMsg_t* msg = call Packet.getPayload(& _packet, sizeof(MoteToMoteMsg_t)); 
					msg -> msgID = packetID++;
					msg -> tag = 0;
					for(i = 0; i < 5; ++i) {
						curr_sample = nonPriority.front->item;
						nonPriority = deleteFront(nonPriority);
						msg->lumArray[i] = curr_sample.data;
						msg->mapArray[i] = curr_sample.id;
					}
					NPattempted++;
					if (r % 100 > LOSSLEVELNP) {
						//Sending the Packet
						NPsent++;
						if (call AMSend.send(AM_BROADCAST_ADDR, & _packet, sizeof(MoteToMoteMsg_t)) == SUCCESS){
							printf("Sending a non-priority packet with ID# %d.\r\n", packetID - 1);
							_radioBusy = TRUE;
							printf("Sample values sent:\r\n");
							for(i = 0; i < 5; i++) {
								printf("%d (#%d) ", msg->lumArray[i],  msg->mapArray[i]);
							}
						}
						else {
							printf("(7)Transmission failed.\r\n");			
						}
					}
					printf("\r\n\n");
				}
				
				if (jcounter == SIZE) {
					// second to last reading
					curr_sample.data = next;
					curr_sample.id = jcounter - 2;
					curr_sample.priority = 0;
				}
				else if(jcounter == SIZE + 1) {
					// last reading
					curr_sample.data = nextnext;					printf("Priority packets re-attepted to send: %d\r\n", PPreattempted);
					printf("Priority packets actually re-sent with %d loss: %d\r\n", LOSSLEVEL, PPresent);
					curr_sample.id = jcounter - 2;
					curr_sample.priority = 0;
				}
				else {	
					prevprev = prev;
					prev = current;
					current = next;
					next = nextnext;
					nextnext = jogdatax[jcounter];
					
					if (current != 0) {
						curr_sample.data = current;
						curr_sample.id = jcounter - 2;
						if (prevprev == 0) { 
						// first 2 readings
							curr_sample.priority = 0;
						}
						else {
							curr_sample.priority = getPriority();
						}
					}
				}	
				if(curr_sample.priority <= PLEVEL) {
					// Put all levels up to and equal to PLEVEL in the priority queue
					priority = enqueue(priority, curr_sample);
				}
				else {
					nonPriority = enqueue(nonPriority, curr_sample);
				}
				
				++jcounter;
			}
			else { 
				//queue not empty, first send the priority packet, pop the queue, and proceed with current readings
				//Creating the Packet
				MoteToMoteMsg_t* msg = call Packet.getPayload(& _packet, sizeof(MoteToMoteMsg_t)); 
				*msg = Front(); 
				Dequeue(msg->msgID);
				PPreattempted++;
				if (r % 100 > LOSSLEVEL) {
					//Sending the Packet
					PPresent++;
					if (call AMSend.send(AM_BROADCAST_ADDR, & _packet, sizeof(MoteToMoteMsg_t)) == SUCCESS){
						printf("Resending packet with ID %d\r\n\n", msg -> msgID);
						_radioBusy = TRUE;
					}	
					else {
						printf("(8)Transmission failed.\r\n");
					}
				}
			}
		}
		else {
			if(jcounter < SIZE + 2) {
				if (jcounter == SIZE) {
					// second to last reading
					curr_sample.data = next;
					curr_sample.id = jcounter - 2;
					curr_sample.priority = 0;
				}
				else if(jcounter == SIZE + 1) {
					// last reading
					curr_sample.data = nextnext;
					curr_sample.id = jcounter - 2;
					curr_sample.priority = 0;
				}
				else {	
					prevprev = prev;
					prev = current;
					current = next;
					next = nextnext;
					nextnext = jogdatax[jcounter];
					
					if (current != 0) {
						curr_sample.data = current;
						curr_sample.id = jcounter - 2;
						if (prevprev == 0) { 
						// first 2 readings
							curr_sample.priority = 0;
						}
						else {
							curr_sample.priority = getPriority();
						}
					}
				}	
				if (current != 0) {	
					if(curr_sample.priority <= PLEVEL) {
						// Put all levels up to and equal to PLEVEL in the priority queue
						priority = enqueue(priority, curr_sample);
					}
					else {
						nonPriority = enqueue(nonPriority, curr_sample);
					}
				}
				++jcounter;
			}
		}
	}
	
	event void AMSend.sendDone(message_t *msg, error_t error) {
		_radioBusy = FALSE;
	}

	event void AMControl.startDone(error_t error) {
		if(error == SUCCESS) { //No error
			printf("Radio Listen begun successfully.\r\n");
		}
		else {
			printf("Error starting AMControl, retrying.\r\n");
			call AMControl.start();
		}
	}
	
	event message_t* Receive.receive(message_t *msg, void *payload, uint8_t len) {
		if(len == sizeof(MoteToMoteMsg_t)) {
			MoteToMoteMsg_t * incomingPacket = (MoteToMoteMsg_t*) payload;
			uint16_t messageID;	
			messageID = incomingPacket -> msgID;
			
			if(front != NULL){ //if queue is not empty
				MoteToMoteMsg_t* frnt = call Packet.getPayload(& _packet, sizeof(MoteToMoteMsg_t));;
				printf("ACK for a priority packet with ID# %d received.\r\n", messageID);
				Dequeue(messageID);
				printf("---------------------------------------------------------\r\n\n");
			}
		}
		return msg;
	}
	
	event void AMControl.stopDone(error_t error) {
		// TODO Auto-generated method stub //If radio stopped
	}

}
