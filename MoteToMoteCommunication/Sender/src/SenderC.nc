#include <UserButton.h>
#include <stdio.h>
#include "Sender.h"

module SenderC
{
	uses //General Interface
	{
		interface Boot;
		interface Leds;
		interface Timer<TMilli>;
	}

	uses //User Button
	{
		interface Get<button_state_t>;
		interface Notify<button_state_t>;
	}
	
	uses //Radio
	{
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface SplitControl as AMControl;
		interface Receive;	
	}
	
	uses //Read
	{
		interface Read<uint16_t> as LightRead;
	}
}
implementation
{	
	bool _radioBusy = FALSE;
	message_t _packet;
	uint64_t counter = 0;
	uint16_t packetID = 0;
	nx_uint16_t tempArray[12];

	event void Boot.booted()
	{
		call Notify.enable();
		call AMControl.start();
		call Timer.startPeriodic(100);
	}

	//When the User Button is pressed the sensor will make a light reading which will trigger a send.
	event void Notify.notify(button_state_t val)
	{
		if (val == BUTTON_PRESSED)
		{
			if(_radioBusy == FALSE)
			{			
				if(call LightRead.read() == SUCCESS)
				{
					call Leds.led1Toggle();
				}
			}
		}
	}

	event void Timer.fired()
	{
		if(call LightRead.read() == SUCCESS)
		{
			call Leds.led0On();
		}
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
			call Leds.led2Toggle();
		}
		else
		{
			call AMControl.start();
		}
	}

	event void LightRead.readDone(error_t result, uint16_t val)
	{
		if(result == SUCCESS)
		{
			if(counter == 0)
			{
				printf("*********************************\r\n");
				printf("Starting transmission...\r\n");
				printf("*********************************\r\n");
				val = 2.5 * val / 4096 * 6250;
				tempArray[counter % 12] = val; 	
				counter++;		
			}
			else if(counter % 12 == 0)
			{
				uint8_t i;
				//Creating the Packet
				MoteToMoteMsg_t* msg = call Packet.getPayload(& _packet, sizeof(MoteToMoteMsg_t)); 
				call Timer.stop();
				msg -> msgID = packetID++;
				for(i = 0; i < 12; i++)
				{
					msg -> lumArray[i] = tempArray[i];
				}
				
				printf("Sending a packet...\r\n");
				printf("Packet ID: %d\r\n", packetID - 1);
				printf("Luminosity values sent:\r\n");
				
				for(i = 0; i < 12; i++)
				{
					printf("%d  ", tempArray[i]);
				}
				printf("\r\n\n");
				
				//Sending the Packet
				if (call AMSend.send(AM_BROADCAST_ADDR, & _packet, sizeof(MoteToMoteMsg_t)) == SUCCESS)
				{
					_radioBusy = TRUE;
				}
				
				//converting and saving lum value to temp array
				val = 2.5 * val / 4096 * 6250;
				tempArray[counter % 12] = val;
				counter++; 	
				
				//Restart timer
				call Timer.startPeriodic(100);			
			}
			else
			{
				//converting and saving lum value to temp array
				val = 2.5 * val / 4096 * 6250;
				tempArray[counter % 12] = val; 	
				counter++;		
			}
		}
		else
		{
			printf("Error reading from light sensor.\r\n");	
		}
	}
	
	event message_t* Receive.receive(message_t *msg, void *payload, uint8_t len)
	{
		uint8_t i;
		printf("Receiving a packet...\r\n");
		if(len == sizeof(MoteToMoteMsg_t))
		{
			MoteToMoteMsg_t * incomingPacket = (MoteToMoteMsg_t*) payload;
			
			uint16_t messageID;
			messageID = incomingPacket -> msgID;
			printf("Packet ID: %d\r\n", messageID);
			printf("Luminocity values received: \r\n");
			for(i = 0; i < 12; i++)
			{
				printf("%d  ", incomingPacket -> lumArray[i]);
			}
			printf("\r\n");
			
			if(messageID == packetID - 1)
			{
				
				printf("*ACK received\r\n");
				printf("------------------------------------\r\n");
				call Leds.led0On();
			}

		}
		return msg;
	}
	
	event void AMControl.stopDone(error_t error)
	{
		// TODO Auto-generated method stub //If radio stopped
	}
	
}