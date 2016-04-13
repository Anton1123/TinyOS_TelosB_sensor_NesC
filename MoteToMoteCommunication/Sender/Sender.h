#ifndef SENDER_H
#define SENDER_H
#include<stdlib.h>
#include<stdio.h>

typedef nx_struct MoteToMoteMsg
{
	nx_uint8_t tag; 
	nx_uint16_t msgID;
	nx_uint16_t lumArray[12]; //25 is max for 8 bit; 12 is max for 16 bit with Data & msgID at 16 bits each
	
} MoteToMoteMsg_t;

enum
{
	AM_RADIO = 6 //AM = ActiveMessage
};

struct Node 
{
	MoteToMoteMsg_t data;
	struct Node* next;
};
// Two global variables to store address of front and rear nodes. 
struct Node* front = NULL;
struct Node* rear = NULL;

// To Enqueue an integer
void Enqueue(MoteToMoteMsg_t packet) 
{
	struct Node* temp = 
		(struct Node*)malloc(sizeof(struct Node));
	temp->data = packet; 
	temp->next = NULL;
	if(front == NULL && rear == NULL)
	{
		front = rear = temp;
		return;
	}
	rear->next = temp;
	rear = temp;
}

// To Dequeue an integer.
void Dequeue() 
{
	struct Node* temp = front;
	if(front == NULL) 
	{
		printf("Queue is Empty\n");
		return;
	}
	if(front == rear) 
	{
		front = rear = NULL;
	}
	else 
	{
		front = front->next;
	}
	free(temp);
}

MoteToMoteMsg_t Front() 
{
	if(front == NULL) 
	{
		printf("Queue is empty\n");
		return;
	}
	return front->data;
}

//void Print() {
//	struct Node* temp = front;
//	while(temp != NULL) {
//		printf("%d ",temp->data);
//		temp = temp->next;
//	}
//	printf("\n");
//}



#endif /* SENDER_H */
