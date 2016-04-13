#include "Receiver.h"

module ReceiverC
{
	uses //General Interface
	{
		interface Boot;
		interface Leds;
	}
	
	uses //Radio
	{
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface SplitControl as AMControl;
		interface Receive;	
	}
}

implementation
{	

	bool _radioBusy = FALSE;
	message_t _packet;
	uint16_t counter = 0;

	event void Boot.booted()
	{
		call AMControl.start();
	}

	event void AMSend.sendDone(message_t *msg, error_t error)
	{
		if (msg == &_packet)
		{
			_radioBusy = FALSE;
		}
	}

	event void AMControl.startDone(error_t error)
	{
		if(error == SUCCESS) //No error
		{
			call Leds.led2On();
		}
		else
		{
			call AMControl.start();
		}
	}
	
	event message_t* Receive.receive(message_t *msg, void *payload, uint8_t len)
	{
		if(len == sizeof(MoteToMoteMsg_t))
		{
			uint8_t i;
			MoteToMoteMsg_t* ack;
			MoteToMoteMsg_t* incomingPacket = (MoteToMoteMsg_t*) payload;
			
			uint16_t messageID;
			
			//Reading the received packet
			messageID = incomingPacket -> msgID;
			
			
			//Creating a packet to broadcast with the information from the received packet
			ack = call Packet.getPayload(& _packet, sizeof(MoteToMoteMsg_t)); 
			ack -> msgID = messageID;
			
			for(i = 0; i < 12; i++)
			{
				ack -> lumArray[i] = incomingPacket -> lumArray[i];
			}

			//Sending the ACK
			if (call AMSend.send(AM_BROADCAST_ADDR, & _packet, sizeof(MoteToMoteMsg_t)) == SUCCESS)
			{
				_radioBusy = TRUE;
			} 
		}
		return msg;
	}
	
	event void AMControl.stopDone(error_t error)
	{
		// TODO Auto-generated method stub //If radio stopped
	}


}