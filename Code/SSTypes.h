//
//  SSTypes.h
//  iSpy
//
//  Created by Milo on 03/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//


typedef struct						    //  Holds data on a particular input.
{
	short inputNum;					    //  The input number.
	short futureUse1;
	unsigned char inputName[32];		//  The input name. (Pascal string)
	unsigned char deviceName[32];		//  The device name. (Pascal string)
	char deviceType;					//  bDeviceTypeLocal, bDeviceTypeDV or bDeviceTypeNetwork.
	char futureUse2;
	short networkDeviceType;			//  The type of network device - bNetworkDeviceType...
	short videoWidth;	
	short videoHeight;
	int futureUse3;
	int futureUse4;
	int futureUse5;
	int futureUse6;
	int futureUse7;
	int futureUse8;
	int futureUse9;
	int futureUse10;
} InputListStruct;


enum		//  Bit masks for the "SS-PTZ" HTTP header of SecuritySpy's MJPEG stream.
{
	bPTZCapabilitiesCanDoPanTilt		= 1,
	bPTZCapabilitiesCanDoHome			= 1 << 1,
	bPTZCapabilitiesCanDoZoom			= 1 << 2
};