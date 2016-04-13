configuration SenderAppC
{
}

implementation
{
	//General
	components SenderC as App;
	components MainC;
	components LedsC;
	components new TimerMilliC();
	
	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Timer -> TimerMilliC;
	
	//For writing into Serial Port
	components SerialPrintfC;
	
	//User Button
	components UserButtonC;
	App.Get -> UserButtonC;
	App.Notify -> UserButtonC;
	
	//Radio Comms
	components ActiveMessageC;
	components new AMSenderC(AM_RADIO);
	components new AMReceiverC(AM_RADIO);

	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC; 
	App.AMControl -> ActiveMessageC;
	App.Receive -> AMReceiverC;
	
	//Light Component
	components new HamamatsuS10871TsrC() as LightSensor;
	App.LightRead -> LightSensor;

}