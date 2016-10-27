configuration ReceiverAppC
{
}

implementation
{
	//General
	components ReceiverC as App;
	components MainC;
	
	App.Boot -> MainC;
	
	components SerialPrintfC;
		
	//Radio Comms
	components ActiveMessageC;
	components new AMSenderC(AM_RADIO);
	components new AMReceiverC(AM_RADIO);
	
	//User Button
	components UserButtonC;
	App.Get -> UserButtonC;
	App.Notify -> UserButtonC;

	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC; 
	App.AMControl -> ActiveMessageC;
	App.Receive -> AMReceiverC;
}