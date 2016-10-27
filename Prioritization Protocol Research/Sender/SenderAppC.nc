configuration SenderAppC
{
}

implementation
{
	//General
	components SenderC as App;
	components MainC;
	components new TimerMilliC();
	
	App.Boot -> MainC;
	App.Timer -> TimerMilliC;
	
	//For writing into Serial Port
	components SerialPrintfC;
	
	//Radio Comms
	components ActiveMessageC;
	components new AMSenderC(AM_RADIO);
	components new AMReceiverC(AM_RADIO);

	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC; 
	App.AMControl -> ActiveMessageC;
	App.Receive -> AMReceiverC;
	
}