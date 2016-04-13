#ifndef RECEIVER_H
#define RECEIVER_H

typedef nx_struct MoteToMoteMsg
{
	nx_uint16_t msgID;
	nx_uint16_t lumArray[12]; //25 is max for 8 bit; 12 is max for 16 bit with Data & msgID at 16 bits each
	
} MoteToMoteMsg_t;

enum
{
	AM_RADIO = 6 //AM = ActiveMessage
};


#endif /* RECEIVER_H */
