#include "Receiver.h"
#include <UserButton.h>
#include <stdio.h>

#define LOSSLEVEL 50

module ReceiverC {
	uses {
		//General Interface
		interface Boot;
	}
	
	uses {
		//Radio
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface SplitControl as AMControl;
		interface Receive;	
	}
	
	uses {
		//User Button
		interface Get<button_state_t>;
		interface Notify<button_state_t>;
	}
}

implementation {	
	bool _radioBusy = FALSE;
	message_t _packet;
	uint16_t PPreceived = 0;
	uint16_t NPreceived = 0;
	uint16_t i;
	int16_t r;

	event void Boot.booted() {
		call Notify.enable();
		for(i = 0; i < SIZE; ++i) {
			receivedData[i] = 0;
		}
		call AMControl.start();
	}

	event void Notify.notify(button_state_t val)
	{
		if (val == BUTTON_PRESSED)
		{
			for(i = 0; i < SIZE; ++i) {
            	interpData[i] = receivedData[i];
			}
            interpolate(interpData);
            printf("\r\nIndex    Rcvd     Predict   Expect\r\n");
			printf("---------------------------------------\r\n");
			for(i = 0; i < SIZE; ++i) {
				if (i / 10 == 0) {
					if(receivedData[i] == 0) {
						printf("%d           %d     %d      %d\r\n", i, receivedData[i], interpData[i], jogdatax[i]);
					}
					else {
						printf("%d        %d     %d      %d\r\n", i, receivedData[i], interpData[i], jogdatax[i]);
					}
				}
				else if (i / 100 == 0) {
					if(receivedData[i] == 0) {
						printf("%d          %d     %d      %d\r\n", i, receivedData[i], interpData[i], jogdatax[i]);
					}
					else {
						printf("%d       %d     %d      %d\r\n", i, receivedData[i], interpData[i], jogdatax[i]);
					}				
				}
				else if (i / 1000 == 0) {
					if(receivedData[i] == 0) {
						printf("%d         %d     %d      %d\r\n", i, receivedData[i], interpData[i], jogdatax[i]);
					}
					else {
						printf("%d      %d     %d      %d\r\n", i, receivedData[i], interpData[i], jogdatax[i]);
					}				
				}
			}
			printf("Priority Packets Received %d.\r\n", PPreceived);
			printf("non-Priority Packets Received %d.\r\n", NPreceived);	
			printf("Total packets received %d.\r\n", PPreceived + NPreceived);	
		}
	}

	event void AMSend.sendDone(message_t *msg, error_t error) {
		if (msg == &_packet) {
			_radioBusy = FALSE;
		}
	}

	event void AMControl.startDone(error_t error) {
		if(error == SUCCESS) {//No error
			printf("Radio listen begun successfully.\r\n");
		}
		else {
			printf("Error Starting AMControl, retrying.\r\n");
			call AMControl.start();
		}
	}
	
	event message_t* Receive.receive(message_t *msg, void *payload, uint8_t len) {
		r = rand();
		if (r < 0)
			r = r*(-1);
		if(len == sizeof(MoteToMoteMsg_t)) {
			MoteToMoteMsg_t* ack;
			MoteToMoteMsg_t* incomingPacket = (MoteToMoteMsg_t*) payload;
			
			uint16_t messageID;
			nx_bool tag;
			
			//Reading the received packet
			messageID = incomingPacket -> msgID;
			tag = incomingPacket -> tag;
			if(tag == 1) {
				//Creating a packet to broadcast with the information from the received packet
				ack = call Packet.getPayload(& _packet, sizeof(MoteToMoteMsg_t)); 
				ack -> msgID = messageID;
				ack -> tag = incomingPacket -> tag;
				
				printf("Priority packet with id %d received. \r\n", messageID);
				printf("Readings received:\r\n");
				for(i = 0; i < 5; i++) {
					printf("%d(#%d)  ", incomingPacket -> lumArray[i], incomingPacket -> mapArray[i]);
					if(incomingPacket -> lumArray[i] != 0) {
						receivedData[incomingPacket -> mapArray[i]] = incomingPacket -> lumArray[i];
					}
				}
				printf("\r\n");
				
				if (r % 100 > LOSSLEVEL) {
					//Sending the ACK
					if (call AMSend.send(AM_BROADCAST_ADDR, & _packet, sizeof(MoteToMoteMsg_t)) == SUCCESS) {
						_radioBusy = TRUE;
						printf("Sending ACK...\r\n");
					} 
				}
				printf("\n");
				PPreceived++;
			}
			else {
				printf("Non-priority packet with id %d received. \r\n", messageID);
				printf("Readings received:\r\n");
				for(i = 0; i < 5; i++) {
					printf("%d(#%d)  ", incomingPacket -> lumArray[i], incomingPacket -> mapArray[i]);
					if(incomingPacket -> lumArray[i] != 0) {
						receivedData[incomingPacket -> mapArray[i]] = incomingPacket -> lumArray[i];
					}
				}
				printf("\r\n\n");
				NPreceived++;
			}
		}
		return msg;
	}
	
	event void AMControl.stopDone(error_t error) {
		// TODO Auto-generated method stub //If radio stopped
	}
}
