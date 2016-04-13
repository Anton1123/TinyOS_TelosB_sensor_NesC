configuration TempTestAppC
{	
}

implementation
{
	//General components
	components TempTestC as App;
	components MainC, LedsC;
	components new TimerMilliC();
	
	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Timer -> TimerMilliC;
	
	//For writing into serial port
	components SerialPrintfC;
	
	//Temperature Component
	components new SensirionSht11C() as TempSensor;
	App.TempRead -> TempSensor.Temperature;	
	
	//Light Component
	components new HamamatsuS10871TsrC() as LightSensor;
	App.LightRead -> LightSensor;
	
	//Humidity Component
	components new SensirionSht11C() as HumiditySensor;
	App.HumidityRead -> HumiditySensor.Humidity;
}