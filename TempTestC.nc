#include <Timer.h>
#include <stdio.h>
#include <string.h>

module TempTestC
{
	uses
	{
		//General Interfaces
		interface Boot;
		interface Timer<TMilli>;
		interface Leds;
	

		//Read
		interface Read<uint16_t> as TempRead;
		interface Read<uint16_t> as LightRead;
		interface Read<uint16_t> as HumidityRead;
	
	}
}

implementation
{
	int count = 0;
	
	event void Boot.booted()
	{
		call Timer.startPeriodic(1000);
		call Leds.led1On();
		
	}

	event void Timer.fired()
	{
		if(call TempRead.read() == SUCCESS)
		{
			call Leds.led2Toggle();
		}
		else
		{
			call Leds.led0Toggle();
		}
				
		if(call LightRead.read() == SUCCESS)
		{
			call Leds.led2Toggle();
		}
		else
		{
			call Leds.led0Toggle();
		}
		
		if(call HumidityRead.read() == SUCCESS)
		{
			call Leds.led2Toggle();
		}
		else
		{
			call Leds.led0Toggle();
		}
		count += 1;
		printf("Reading # %d \r\n", count);
	}

	event void TempRead.readDone(error_t result, uint16_t val)
	{
		if(result == SUCCESS)
		{
			//now we can read sensor value
			val = -39.6 + 0.018 * val;
			printf("Current temp is: %d degree Fahrenheit.\r\n", val);
		}
		else
		{
			//there was a problem
			printf("Error reading from temp sensor.\r\n");
		}
	}

	event void LightRead.readDone(error_t result, uint16_t val)
	{
		if(result == SUCCESS)
		{
			//now we can read sensor value
			val = 2.5 * val / 4096.0 * 6250.0;
			printf("Current luminocity is: %d\r\n", val);
		}
		else
		{
			//there was a problem
			printf("Error reading from light sensor.\r\n");
		}	
	}

	event void HumidityRead.readDone(error_t result, uint16_t val)
	{
		if(result == SUCCESS)
		{
			//now we can read sensor value
			val = val * 0.0405 - val * val * 0.0000028 - 4;
			printf("Current humidity is: %d %\r\n\n", val);
		}
		else
		{
			//there was a problem
			printf("Error reading from humidity sensor.\r\n\n");
		}	
	}
}