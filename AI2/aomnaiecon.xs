//==============================================================================
// AoMNaiEcon.xs
//
// Handles common economy functions.
//==============================================================================
// *****************************************************************************
//
// maintainUnit
//
// Maintain a total of qty units of type unitID, optionally gathering at gatherPoint and 
// training at a minimum of interval seconds apart.  Returns the planID, or -1 on failure.
// *****************************************************************************
int   maintainUnit( int unitID=-1, int qty=1, vector gatherPoint=vector(-1,-1,-1), int interval=-1)
{

   if (unitID == -1)
      return(-1);
   if (qty < 1)
      return(-1);
   int planID = aiPlanCreate("Maintain "+qty+" "+kbGetProtoUnitName(unitID), cPlanTrain);
	if (planID >= 0)
	{
		aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, unitID);
		aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, qty);
      if (interval > 0)
   		aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, interval);
      if (xsVectorGetX(gatherPoint) >= 0)
   		aiPlanSetVariableVector(planID, cTrainPlanGatherPoint, 0, gatherPoint);
		aiPlanSetActive(planID);
      return(planID);
	}
   else
      return(-1);
}
//==============================================================================
//iAmNative
// Just a little function to clear up the confusion between Thor and the new
// native culture.
//==============================================================================
bool iAmNative()
{
	if (cMyCiv == cCivThor)
		return(true);
	else
		return(false);
}

//==============================================================================
// getEconPop
//
// Returns the unit count of villagers, dwarves, fishing boats, trade carts and oxcarts.
//==============================================================================
int getEconPop(void)
{
   int retVal = 0;

   retVal = retVal + kbUnitCount(cMyID, gGatherer, cUnitStateAlive);

   retVal = retVal + kbUnitCount(cMyID, cUnitTypeDwarf, cUnitStateAlive);
   retVal = retVal + kbUnitCount(cMyID, cUnitTypeFishingShipGreek, cUnitStateAlive);
   retVal = retVal + kbUnitCount(cMyID, cUnitTypeFishingShipNorse, cUnitStateAlive);
   retVal = retVal + kbUnitCount(cMyID, cUnitTypeFishingShipEgyptian, cUnitStateAlive);
   retVal = retVal + kbUnitCount(cMyID, cUnitTypeFishingShipAtlantean, cUnitStateAlive);   
   retVal = retVal + kbUnitCount(cMyID, cUnitTypeAbstractTradeUnit, cUnitStateAlive);
   retVal = retVal + kbUnitCount(cMyID, cUnitTypeOxCart, cUnitStateAlive);

   return(retVal);
}




//==============================================================================
// getMilPop
//
// Returns the pop slots used by military units
//==============================================================================
int getMilPop(void)
{
   return(kbGetPop() - getEconPop());
}


//==============================================================================
// findUnit
//
// Will find the first unit of the given playerID
//==============================================================================
int findUnit(int playerID=0, int state=cUnitStateAny, int unitTypeID=-1)
{
   int count=-1;
   static int unitQueryID=-1;

   //If we don't have the query yet, create one.
   if (unitQueryID < 0)
      unitQueryID=kbUnitQueryCreate("miscFindUnitQuery");
   
	//Define a query to get all matching units
	if (unitQueryID != -1)
	{
		kbUnitQuerySetPlayerID(unitQueryID, playerID);
      kbUnitQuerySetUnitType(unitQueryID, unitTypeID);
      kbUnitQuerySetState(unitQueryID, state);
	}
	else
   	return(-1);

   kbUnitQueryResetResults(unitQueryID);
	int numberFound=kbUnitQueryExecute(unitQueryID);
   for (i=0; < numberFound)
      return(kbUnitQueryGetResult(unitQueryID, i));
   return(-1);
}

//==============================================================================
// findNumberOfUnitsInBase
//
//==============================================================================
int findNumberOfUnitsInBase(int playerID=0, int baseID=-1, int unitTypeID=-1)
{
   int count=-1;
   static int unitQueryID=-1;

   //Create the query if we don't have it.
   if (unitQueryID < 0)
      unitQueryID=kbUnitQueryCreate("getUnitsInBaseQuery");
   
	//Define a query to get all matching units
	if (unitQueryID != -1)
	{
		kbUnitQuerySetPlayerID(unitQueryID, playerID);
      kbUnitQuerySetBaseID(unitQueryID, baseID);
      kbUnitQuerySetUnitType(unitQueryID, unitTypeID);
      kbUnitQuerySetState(unitQueryID, cUnitStateAny);
	}
	else
   	return(-1);

   kbUnitQueryResetResults(unitQueryID);
	return(kbUnitQueryExecute(unitQueryID));
}

//==============================================================================
// findBestSettlement
//
// Will find the closet settlement of the given playerID
//==============================================================================
vector findBestSettlement(int playerID=0)
{
   vector townLocation=kbGetTownLocation();
   vector best=townLocation;

   int count=-1;
   static int unitQueryID=-1;

   //Create the query if we don't have it yet.
   if (unitQueryID < 0)
      unitQueryID=kbUnitQueryCreate("getUnClaimedSettlements");
   
	//Define a query to get all matching units.
	if (unitQueryID != -1)
	{
		kbUnitQuerySetPlayerID(unitQueryID, playerID);
      kbUnitQuerySetUnitType(unitQueryID, cUnitTypeSettlement);
      kbUnitQuerySetState(unitQueryID, cUnitStateAny);
	}
	else
   	return(best);

   //Find the best one.
	float bestDistSqr=100000000.0;
   kbUnitQueryResetResults(unitQueryID);
	int numberFound=kbUnitQueryExecute(unitQueryID);
   for (i=0; < numberFound)
   {
      vector position=kbUnitGetPosition(kbUnitQueryGetResult(unitQueryID, i));
      float dx=xsVectorGetX(townLocation)-xsVectorGetX(position);
      float dz=xsVectorGetZ(townLocation)-xsVectorGetZ(position);
      
      float curDistSqr=((dx*dx) + (dz*dz));
      if(curDistSqr < bestDistSqr)
      {
         best=position;
         bestDistSqr=curDistSqr;
      }
   }
   return(best);
}

//==============================================================================
// findASettlement
//
// Will find an unclaimed settlement
//==============================================================================
bool findASettlement()
{
   int count=-1;
   static int unitQueryID=-1;

   //Create the query if we don't have it yet.
   if (unitQueryID < 0)
      unitQueryID=kbUnitQueryCreate("getAnUnClaimedSettlements");
   
	//Define a query to get all matching units.
	if (unitQueryID != -1)
	{
		kbUnitQuerySetPlayerID(unitQueryID, 0);
      kbUnitQuerySetUnitType(unitQueryID, cUnitTypeSettlement);
      kbUnitQuerySetState(unitQueryID, cUnitStateAny);
	}
	else
   	return(false);

   kbUnitQueryResetResults(unitQueryID);
	int numberFound=kbUnitQueryExecute(unitQueryID);
   if (numberFound > 0)
      return(true);
   return(false);
}

//==============================================================================
// getNumberUnits
//==============================================================================
int getNumberUnits(int unitType=-1, int playerID=-1, int state=cUnitStateAlive)
{
	int count=-1;
   static int unitQueryID=-1;

   //Create the query if we don't have it yet.
   if (unitQueryID < 0)
      unitQueryID=kbUnitQueryCreate("GetNumberOfUnitsQuery");
   
	//Define a query to get all matching units.
	if (unitQueryID != -1)
	{
		kbUnitQuerySetPlayerID(unitQueryID, playerID);
      kbUnitQuerySetUnitType(unitQueryID, unitType);
      kbUnitQuerySetState(unitQueryID, state);
	}
	else
   	return(0);

	kbUnitQueryResetResults(unitQueryID);
	return(kbUnitQueryExecute(unitQueryID));
}

//==============================================================================
// getUnit
//==============================================================================
int getUnit(int unitType=-1)
{
  	int retVal=-1;
   int count=-1;
	static int unitQueryID=-1;
   
   //Create the query if we don't have it yet.
   if (unitQueryID < 0)
      unitQueryID=kbUnitQueryCreate("getUnitQuery");

	//Define a query to get all matching units.
	if (unitQueryID != -1)
	{
		kbUnitQuerySetPlayerID(unitQueryID, cMyID);
      kbUnitQuerySetUnitType(unitQueryID, unitType);
      kbUnitQuerySetState(unitQueryID, cUnitStateAlive);
	}
	else
   	return(-1);

   kbUnitQueryResetResults(unitQueryID);
	count=kbUnitQueryExecute(unitQueryID);

	//Pick a unit and return its ID, or return -1.
	if (count > 0)
      retVal=kbUnitQueryGetResult(unitQueryID, 0);
	return(retVal);
}

//==============================================================================
// getNextGathererUpgrade
//
// sets up a progression plan to research the next upgrade that benefits the given
// resource.
//==============================================================================
rule getNextGathererUpgrade
   minInterval 30
   inactive
   runImmediately
{
   if (cMyCulture != cCultureAtlantean)
      if (kbSetupForResource(kbBaseGetMainID(cMyID), cResourceWood, 25.0, 600) == false)
         return;

   static int id=0;

	int gathererTypeID=gGatherer;
	if (gathererTypeID < 0)
      return();
	
	for (i=0; < 3)
   {
      int affectedUnitType=-1;
      if (i == cResourceGold)
         affectedUnitType=cUnitTypeGold;
      else if (i == cResourceWood)
         affectedUnitType=cUnitTypeWood;
      else //(i == cResourceFood)
      {
         //If we're not farming yet, don't get anything.
         if (gFarming != true)
            continue;
         if (kbUnitCount(cMyID, cUnitTypeFarm, cUnitStateAlive) >= 0)   // Farms always first
            affectedUnitType=cUnitTypeFarm;
      }

      //Get the building that we drop this resource off at.
	   int dropSiteFilterID=kbTechTreeGetDropsiteUnitIDByResource(i, 0);
      if (cMyCulture == cCultureAtlantean)
         dropSiteFilterID = cUnitTypeGuild;  // All econ techs at guild
	   if (dropSiteFilterID < 0)
		   continue;

      //Don't do anything until you have a dropsite.
      if (getUnit(dropSiteFilterID) == -1)
         continue;

      //Get the cheapest thing.
	   int upgradeTechID=kbTechTreeGetCheapestUnitUpgrade(gathererTypeID, cUpgradeTypeWorkRate, -1, dropSiteFilterID, false, affectedUnitType);
	   if (upgradeTechID < 0)
		   continue;
	   //Dont make another plan if we already have one.
      if (aiPlanGetIDByTypeAndVariableType(cPlanProgression, cProgressionPlanGoalTechID, upgradeTechID) != -1)
         continue;

      //Make plan to get this upgrade.
	   int planID=aiPlanCreate("nextGathererUpgrade - "+id, cPlanProgression);
	   if (planID < 0)
		   continue;

	   aiPlanSetVariableInt(planID, cProgressionPlanGoalTechID, 0, upgradeTechID);
	   aiPlanSetDesiredPriority(planID, 25);
	   aiPlanSetEscrowID(planID, cEconomyEscrowID);
	   aiPlanSetActive(planID);
      aiEcho("**** getNextGathererUpgrade: successful in creating a progression to "+kbGetTechName(upgradeTechID));
	   id++;
   }
}


//==============================================================================
// findBiggestBorderArea
//
// given an areaid, find the biggest border area in tiles.
//==============================================================================
int findBiggestBorderArea(int areaID=-1)
{
	if(areaID == -1)
		return(-1);

	int numBorders=kbAreaGetNumberBorderAreas(areaID);
	int borderArea=-1;
	int numTiles=-1;
	int bestTiles=-1;
	int bestArea=-1;

	for (i=0; < numBorders)
	{
		borderArea=kbAreaGetBorderAreaID(areaID, i);
		numTiles=kbAreaGetNumberTiles(borderArea);
		if (numTiles > bestTiles)
		{
			bestTiles=numTiles;
			bestArea=borderArea;
		}
	}

	return(bestArea);
}

//==============================================================================
// RULE: UpdateWoodBreakdown
//==============================================================================
rule updateWoodBreakdown
   minInterval 12
   inactive
   group startRules
{
   int mainBaseID = kbBaseGetMainID(cMyID);

   int woodPriority=50;
   if (cMyCulture == cCultureEgyptian)
      woodPriority=55;

   int gathererCount = kbUnitCount(cMyID,cUnitTypeAbstractVillager,cUnitStateAlive);
   int woodGathererCount = 0.5 + aiGetResourceGathererPercentage(cResourceWood, cRGPActual) * gathererCount;

   // If we have no need for wood, set plans=0 and exit
   if (woodGathererCount <= 0)
   {
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumWoodPlans, 0, 0);
      aiRemoveResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, mainBaseID);
      if (gWoodBaseID != mainBaseID)
         aiRemoveResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, gWoodBaseID);
      //aiEcho("    No wood cutters needed.");
      return;
   }

   // If we're this far, we need some wood gatherers.  The number of plans we use will be the greater of 
   // a) the ideal number for this number of gatherers, or
   // b) the number of plans active that have resource sites, either main base or wood base.

   //Count of sites.
   int numberMainBaseSites=kbGetNumberValidResources(mainBaseID, cResourceWood, cAIResourceSubTypeEasy);
   int numberWoodBaseSites = 0;
   if ( (gWoodBaseID >= 0) && (gWoodBaseID != mainBaseID) )    // Count wood base if different
      numberWoodBaseSites = kbGetNumberValidResources(gWoodBaseID, cResourceWood, cAIResourceSubTypeEasy);

   //Get the count of plans we currently have going.
   int numWoodPlans=aiPlanGetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumWoodPlans, 0);

   int desiredWoodPlans = 1 + (woodGathererCount/12);

   if (desiredWoodPlans < numWoodPlans)
      desiredWoodPlans = numWoodPlans;    // Try to preserve existing plans

   // Three cases are possible:
   // 1)  We have enough sites at our main base.  All should work in main base.
   // 2)  We have some wood at main, but not enough.  Split the sites
   // 3)  We have no wood at main...use woodBase

   if (numberMainBaseSites >= desiredWoodPlans) // case 1
   {
      // remove any breakdown for woodBaseID
      if (gWoodBaseID != mainBaseID)
         aiRemoveResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, gWoodBaseID);
      gWoodBaseID = mainBaseID;
      aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, desiredWoodPlans, woodPriority, 1.0, mainBaseID);
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumWoodPlans, 0, desiredWoodPlans);
      return;
   }

   if ( (numberMainBaseSites > 0) && (numberMainBaseSites < desiredWoodPlans) )  // case 2
   {
      aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, numberMainBaseSites, woodPriority, 1.0, mainBaseID);

      if (numberWoodBaseSites > 0)  // We do have remote wood
      {
         aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, desiredWoodPlans-numberMainBaseSites, woodPriority, 1.0, gWoodBaseID);
         aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumWoodPlans, 0, desiredWoodPlans);
      }
      else  // No remote wood...bummer.  Kill old breakdown, look for more
      {
         aiRemoveResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, gWoodBaseID);   // Remove old breakdown
         //Try to find a new wood base.
         gWoodBaseID=kbBaseFindCreateResourceBase(cResourceWood, cAIResourceSubTypeEasy, kbBaseGetMainID(cMyID));
         if (gWoodBaseID >= 0)
         {
            aiEcho("    New wood base is "+gWoodBaseID);
            aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumWoodPlans, 0, desiredWoodPlans);      // We can have the full amount
	         aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, desiredWoodPlans-numberMainBaseSites, woodPriority, 1.0, gWoodBaseID);
         }
         else
         {
            aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumWoodPlans, 0, numberMainBaseSites);   // That's all we get
         }
      }
      return;
   }

   if (numberMainBaseSites < 1)  // case 3
   {
      aiRemoveResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy,mainBaseID);

      if (numberWoodBaseSites >= desiredWoodPlans)  // We have enough remote wood
      {
         aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, desiredWoodPlans, woodPriority, 1.0, gWoodBaseID);
         aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumWoodPlans, 0, desiredWoodPlans);
      }
      else if (numberWoodBaseSites > 0)   // We have some, but not enough
      {
         aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, numberWoodBaseSites, woodPriority, 1.0, gWoodBaseID);
         aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumWoodPlans, 0, numberWoodBaseSites);
      }
      else  // We have none, try elsewhere
      {
         aiRemoveResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, gWoodBaseID);   // Remove old breakdown
         //Try to find a new wood base.
         gWoodBaseID=kbBaseFindCreateResourceBase(cResourceWood, cAIResourceSubTypeEasy, kbBaseGetMainID(cMyID));
         if (gWoodBaseID >= 0)
         {
            aiEcho("    New wood base is "+gWoodBaseID);
            numberWoodBaseSites = kbGetNumberValidResources(gWoodBaseID, cResourceWood, cAIResourceSubTypeEasy);
            if (numberWoodBaseSites < desiredWoodPlans)
               desiredWoodPlans = numberWoodBaseSites;
            aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumWoodPlans, 0, desiredWoodPlans);      
	         aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, desiredWoodPlans, woodPriority, 1.0, gWoodBaseID);
         }
      }
      return;
   }
}

//==============================================================================
// RULE: UpdateGoldBreakdown
//==============================================================================
rule updateGoldBreakdown
   minInterval 13
   inactive
   group startRules
{

   int mainBaseID = kbBaseGetMainID(cMyID);

   int goldPriority=49; // Lower than wood for non-Egyptians
   if (cMyCulture == cCultureEgyptian)    // Higher than Egyptian wood
      goldPriority=56;

   int gathererCount = kbUnitCount(cMyID,cUnitTypeAbstractVillager,cUnitStateAlive);
   int goldGathererCount = 0.5 + aiGetResourceGathererPercentage(cResourceGold, cRGPActual) * gathererCount;

   // If we have no need for gold, set plans=0 and exit
   if (goldGathererCount <= 0)
   {
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumGoldPlans, 0, 0);
      aiRemoveResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, mainBaseID);
      if (gGoldBaseID != mainBaseID)
         aiRemoveResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, gGoldBaseID);
      return;
   }

   // If we're this far, we need some gold gatherers.  The number of plans we use will be the greater of 
   // a) the ideal number for this number of gatherers, or
   // b) the number of plans active that have resource sites, either main base or gold base.

   //Count of sites.
   int numberMainBaseSites=kbGetNumberValidResources(mainBaseID, cResourceGold, cAIResourceSubTypeEasy);
   int numberGoldBaseSites = 0;
   if ( (gGoldBaseID >= 0) && (gGoldBaseID != mainBaseID) )    // Count gold base if different
      numberGoldBaseSites = kbGetNumberValidResources(gGoldBaseID, cResourceGold, cAIResourceSubTypeEasy);

   //Get the count of plans we currently have going.
   int numGoldPlans=aiPlanGetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumGoldPlans, 0);

   int desiredGoldPlans = 1 + (goldGathererCount/12);

   if (desiredGoldPlans < numGoldPlans)
      desiredGoldPlans = numGoldPlans;    // Try to preserve existing plans

   // Three cases are possible:
   // 1)  We have enough sites at our main base.  All should work in main base.
   // 2)  We have some gold at main, but not enough.  Split the sites
   // 3)  We have no gold at main...use goldBase

   if (numberMainBaseSites >= desiredGoldPlans) // case 1
   {
      // remove any breakdown for goldBaseID
      if (gGoldBaseID != mainBaseID)
         aiRemoveResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, gGoldBaseID);
      gGoldBaseID = mainBaseID;
      aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, desiredGoldPlans, goldPriority, 1.0, mainBaseID);
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumGoldPlans, 0, desiredGoldPlans);
      return;
   }

   if ( (numberMainBaseSites > 0) && (numberMainBaseSites < desiredGoldPlans) )  // case 2
   {
      aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, numberMainBaseSites, goldPriority, 1.0, mainBaseID);

      if (numberGoldBaseSites > 0)  // We do have remote gold
      {
         aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, desiredGoldPlans-numberMainBaseSites, goldPriority, 1.0, gGoldBaseID);
         aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumGoldPlans, 0, desiredGoldPlans);
      }
      else  // No remote gold...bummer.  Kill old breakdown, look for more
      {
         aiRemoveResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, gGoldBaseID);   // Remove old breakdown
         //Try to find a new gold base.
         gGoldBaseID=kbBaseFindCreateResourceBase(cResourceGold, cAIResourceSubTypeEasy, kbBaseGetMainID(cMyID));
         if (gGoldBaseID >= 0)
         {
            aiEcho("    New gold base is "+gGoldBaseID);
            aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumGoldPlans, 0, desiredGoldPlans);      // We can have the full amount
	         aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, desiredGoldPlans-numberMainBaseSites, goldPriority, 1.0, gGoldBaseID);
         }
         else
         {
            aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumGoldPlans, 0, numberMainBaseSites);   // That's all we get
         }
      }
      return;
   }


   if (numberMainBaseSites < 1)  // case 3
   {
      aiRemoveResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy,mainBaseID);

      if (numberGoldBaseSites >= desiredGoldPlans)  // We have enough remote gold
      {
         aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, desiredGoldPlans, goldPriority, 1.0, gGoldBaseID);
         aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumGoldPlans, 0, desiredGoldPlans);
      }
      else if (numberGoldBaseSites > 0)   // We have some, but not enough
      {
         aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, numberGoldBaseSites, goldPriority, 1.0, gGoldBaseID);
         aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumGoldPlans, 0, numberGoldBaseSites);
      }
      else  // We have none, try elsewhere
      {
         aiRemoveResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, gGoldBaseID);   // Remove old breakdown
         //Try to find a new gold base.
         gGoldBaseID=kbBaseFindCreateResourceBase(cResourceGold, cAIResourceSubTypeEasy, kbBaseGetMainID(cMyID));
         if (gGoldBaseID >= 0)
         {
            aiEcho("    New gold base is "+gGoldBaseID);
            numberGoldBaseSites = kbGetNumberValidResources(gGoldBaseID, cResourceGold, cAIResourceSubTypeEasy);
            if (numberGoldBaseSites < desiredGoldPlans)
               desiredGoldPlans = numberGoldBaseSites;
            aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumGoldPlans, 0, desiredGoldPlans);      
	         aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, desiredGoldPlans, goldPriority, 1.0, gGoldBaseID);
         }
      }
      return;
   }
}

//==============================================================================
// updateFoodBreakdown
//==============================================================================
rule updateFoodBreakdown
   minInterval 9
   inactive
   group startRules
{
	
   int mainBaseID = kbBaseGetMainID(cMyID);
   int numAggressivePlans = aiGetResourceBreakdownNumberPlans(cResourceFood, cAIResourceSubTypeHuntAggressive, mainBaseID );

      
   float distance = gMaximumBaseResourceDistance - 10.0;    // Make sure we don't get resources near perimeter that might wander out of range.
   //Get the number of valid resources spots.
   int numberAggressiveResourceSpots=kbGetNumberValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeHuntAggressive, distance);

   if ( (aiGetWorldDifficulty() == cDifficultyEasy) && (cvRandomMapName != "erebus") ) // Changed 8/18/03 to force Easy hunting on Erebus.
      numberAggressiveResourceSpots = 0;  // Never get enough vills to go hunting.

   int numberEasyResourceSpots=kbGetNumberValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeEasy, distance);
   if ( kbUnitCount(cMyID, cUnitTypeHerdable) > 0)
   {     // We have herdables, make up for the fact that the resource count excludes them.
      numberEasyResourceSpots = numberEasyResourceSpots + 1;
   }
   int numberHuntResourceSpots = kbGetNumberValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeHunt, distance);
   int totalNumberResourceSpots=numberAggressiveResourceSpots + numberEasyResourceSpots + numberHuntResourceSpots;
//   // aiEcho("Food resources:  "+numberAggressiveResourceSpots+" aggressive, "+numberHuntResourceSpots+" hunt, and "+numberEasyResourceSpots+" easy.");

   float aggressiveAmount=kbGetAmountValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeHuntAggressive, distance);
   float easyAmount=kbGetAmountValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeEasy, distance);
   easyAmount = easyAmount + 100* kbUnitCount(cMyID, cUnitTypeHerdable);      // Add in the herdables, overlooked by the kbGetAmount call.
   float huntAmount=kbGetAmountValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeHunt, distance);
   float totalAmount=aggressiveAmount+easyAmount+huntAmount;
   // aiEcho("Food amounts:  "+aggressiveAmount+" aggressive, "+huntAmount+" hunt, and "+easyAmount+" easy.");
   
   // Only do one aggressive site at a time, they tend to take lots of gatherers
   if (numberAggressiveResourceSpots > 1)
      numberAggressiveResourceSpots = 1;

   totalNumberResourceSpots=numberAggressiveResourceSpots + numberEasyResourceSpots + numberHuntResourceSpots;

   int gathererCount = kbUnitCount(cMyID,gGatherer,cUnitStateAlive);
   if (cMyCulture == cCultureNorse)
      gathererCount = gathererCount + kbUnitCount(cMyID,gGatherer,cUnitStateAlive);  // dwarves
   int foodGathererCount = 0.5 + aiGetResourceGathererPercentage(cResourceFood, cRGPActual) * gathererCount;

   if (foodGathererCount <= 0)
      foodGathererCount = 1;     // Avoid div 0

   // Preference order is existing farms (except in age 1), new farms if low on food sites, aggressive hunt (size permitting), hunt, easy, then age 1 farms.  
   // MK:  "hunt" isn't supported in the kbGetNumberValidResource calls, but if we add it, this code should use it properly.
   int aggHunters = 0;
   int hunters = 0;
   int easy = 0;
   int farmers = 0;
   int unassigned = foodGathererCount;
   int farmerReserve = 0;  // Number of farms we already have, use them first unless Egypt first age (slow slow farming)
   int farmerPreBuild = 0; // Number of farmers to ask for ahead of time when food starts running low.

   if ( (gFarmBaseID >= 0) /*&& (kbGetAge() > cAge1)*/)      // Farms get first priority 
      farmerReserve = kbBaseGetNumberUnits( cMyID, gFarmBaseID, -1, cUnitTypeFarm);

   if (farmerReserve > unassigned)
      farmerReserve = unassigned;   // Can't reserve more than we have!

   if ((farmerReserve > 0) && (kbGetAge()>cAge1) )
   {
      unassigned = unassigned - farmerReserve;
   }

   if ( (aiGetGameMode() == cGameModeLightning) || (aiGetGameMode() == cGameModeDeathmatch) )
      totalAmount = 200;   // Fake a shortage so that farming always starts early in these game modes
   if ( (kbGetAge() > cAge1) || (cMyCulture == cCultureEgyptian) )   // can build farms
   {
      if ( ((totalNumberResourceSpots < 2) && (xsGetTime() > 150000)) || (totalAmount <= (500 + 50*foodGathererCount)) || (kbGetAge()==cAge3) )
      {  // Start building if only one spot left, or if we're low on food.  In age 3, start farming anyway.
         farmerPreBuild = 4;  // Starting prebuild
         if (cMyCulture == cCultureAtlantean)
            farmerPreBuild = 2;
         if (farmerPreBuild > unassigned)
            farmerPreBuild = unassigned;
         //// aiEcho("Reserving "+farmerPreBuild+" slots for prebuilding farms.");
         unassigned = unassigned - farmerPreBuild;
         if (farmerPreBuild > 0)
				gFarming = true;
      }
   }
   // Want 1 plan per 12 vills, or fraction thereof.
   int numPlansWanted = 1 + unassigned/12;
   if (cMyCulture == cCultureAtlantean)
      numPlansWanted = 1 + unassigned/4;
   if (unassigned == 0)
      numPlansWanted = 0;

   if (numPlansWanted > totalNumberResourceSpots)
   {
      numPlansWanted = totalNumberResourceSpots;
   }
   int numPlansUnassigned = numPlansWanted;


   int minVillsToStartAggressive = aiGetMinNumberNeedForGatheringAggressives()+0;    // Don't start a new aggressive plan unless we have this many vills...buffer above strict minimum.
   if (cMyCulture == cCultureAtlantean)
      minVillsToStartAggressive = aiGetMinNumberNeedForGatheringAggressives()+0;

  
// Start a new plan if we have enough villies and we have the resource.
// If we have a plan open, don't kill it as long as we are within 2 of the needed min...the plan will steal from elsewhere.
   if ( (numPlansUnassigned > 0) && (numberAggressiveResourceSpots > 0)
        && ( (unassigned > minVillsToStartAggressive)|| ((numAggressivePlans>0) && (unassigned>=(aiGetMinNumberNeedForGatheringAggressives()-2))) ) )    // Need a plan, have resources and enough hunters...or one plan exists already.
   {
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHuntAggressive, 1);
      //// aiEcho("Making 1 aggressive plan.");
      aggHunters = aiGetMinNumberNeedForGatheringAggressives();	// This plan will over-grab due to high priority
      if (numPlansUnassigned == 1)
         aggHunters = unassigned;   // use them all if we're small enough for 1 plan
      numPlansUnassigned = numPlansUnassigned - 1;
      unassigned = unassigned - aggHunters;
      numberAggressiveResourceSpots = 1;  // indicates 1 used
   }
   else  // Can't go aggressive
   {
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHuntAggressive, 0);
      numberAggressiveResourceSpots = 0;  // indicate none used
   }

   if ( (numPlansUnassigned > 0) && (numberHuntResourceSpots > 0) )
   {
      if (numberHuntResourceSpots > numPlansUnassigned)
         numberHuntResourceSpots = numPlansUnassigned;
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHunt, numberHuntResourceSpots);
      hunters = (numberHuntResourceSpots * unassigned) / numPlansUnassigned;  // If hunters are 2 of 3 plans, they get 2/3 of gatherers.
      unassigned = unassigned - hunters;
      numPlansUnassigned = numPlansUnassigned - numberHuntResourceSpots;
   }
   else
   {
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHunt, 0);
      numberHuntResourceSpots = 0;
   }

   if ( (numPlansUnassigned > 0) && (numberEasyResourceSpots > 0) )
   {
      if (numberEasyResourceSpots > numPlansUnassigned)
         numberEasyResourceSpots = numPlansUnassigned;
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeEasy, numberEasyResourceSpots);
      easy = (numberEasyResourceSpots * unassigned) / numPlansUnassigned;
      unassigned = unassigned - easy;
      numPlansUnassigned = numPlansUnassigned - numberEasyResourceSpots;
   }
   else
   {
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeEasy, 0);
      numberEasyResourceSpots = 0;
   }

   // If we still have some unassigned, and we're in the first age, and we're not egyptian, try to dump them into a plan.
   if ( (kbGetAge() == cAge1) && (unassigned > 0) && (cMyCulture != cCultureEgyptian) )
   {
      if ( (aggHunters > 0) && (unassigned > 0) )
      {
         aggHunters = aggHunters + unassigned;
         unassigned = 0;
      }
      if ( (hunters > 0) && (unassigned > 0) )
      {
         hunters = hunters + unassigned;
         unassigned = 0;
      }
      if ( (easy > 0) && (unassigned > 0) )
      {
         easy = easy + unassigned;
         unassigned = 0;
      }

      // If we're here and unassigned > 0, we'll just make an easy plan and dump them there, hoping
      // that there's easy food somewhere outside our base.
      //// aiEcho("Making an emergency easy plan.");
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeEasy, numberEasyResourceSpots+1);
      easy = easy + unassigned;
      unassigned = 0;
      if ( (gMaximumBaseResourceDistance < 110.0) && (kbGetAge()<cAge2) )
      {
         gMaximumBaseResourceDistance = gMaximumBaseResourceDistance + 10.0;
         // aiEcho("**** Expanding gather radius to "+gMaximumBaseResourceDistance);
      }
   }  
  
 
   // Now, the number of farmers we want is the unassigned total, plus reserve (existing farms) and prebuild (plan ahead).
   farmers =farmerReserve + farmerPreBuild;
   unassigned = unassigned - farmers;

   if (unassigned > 0)
   {  // Still unassigned?  Make an extra easy plan, hope they can find food somewhere
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeEasy, numberEasyResourceSpots+1);
      easy = easy + unassigned;
      unassigned = 0;
   }

   int numFarmPlansWanted = 0;
   if (farmers > 0)
   {
      numFarmPlansWanted = 1 + ( farmers / aiPlanGetVariableInt(gGatherGoalPlanID, cGatherGoalPlanFarmLimitPerPlan, 0) );
      gFarming = true;
   }
   else
		gFarming = false;

   //Egyptians can farm in the first age.
   if (((kbGetAge() > 0) || (cMyCulture == cCultureEgyptian)) && (gFarmBaseID != -1) && (xsGetTime() > 180000))
   {
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeFarm, numFarmPlansWanted);
   }
   else
   {
      numFarmPlansWanted = 0;
   }

   // aiEcho("Assignments are "+aggHunters+" aggressive hunters, "+hunters+" hunters, "+easy+" gatherers, and "+farmers+" farmers.");

   //Set breakdown based on goals.
   aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFarm, numFarmPlansWanted, 90, (100.0*farmers)/(foodGathererCount*100.0), gFarmBaseID);
   aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHuntAggressive, numberAggressiveResourceSpots, 45, (100.0*aggHunters)/(foodGathererCount*100.0), mainBaseID);
   aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHunt, numberHuntResourceSpots, , 66, (100.0*hunters)/(foodGathererCount*100.0), mainBaseID);
   aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeEasy, numberEasyResourceSpots, 65, (100.0*easy)/(foodGathererCount*100.0), mainBaseID);
}

//==============================================================================
// updateResourceHandler
//==============================================================================
void updateResourceHandler(int parm=0)
{
   //Handle food.
   if (parm == cResourceFood)
   {
      updateFoodBreakdown();
   }
   //Handle Gold.
   if (parm == cResourceGold)
   {
      updateGoldBreakdown();
      xsEnableRule("updateGoldBreakdown");
   }
   //Handle Wood.
   if (parm == cResourceWood)
   {
      updateWoodBreakdown();
      xsEnableRule("updateWoodBreakdown");
   }
}

//==============================================================================
// RULE: relocateFarming
//==============================================================================
rule relocateFarming
   minInterval 30
   inactive
{
   //Not farming yet, don't do anything.
   if (gFarming == false)
      return;

   //Fixup the old RB for farming.
   if (gFarmBaseID != -1)
   {
      //Check the current farm base for a settlement.
      if (findNumberOfUnitsInBase(cMyID, gFarmBaseID, cUnitTypeAbstractSettlement) > 0)
         return;
      //Remove the old breakdown.
      aiRemoveResourceBreakdown(cResourceFood, cAIResourceSubTypeFarm, gFarmBaseID);
   }

   //If no settlement, then move the farming to another base that has a settlement.
   int unit=findUnit(cMyID, cUnitStateAlive, cUnitTypeAbstractSettlement);
   if (unit != -1)
   {
      //Get new base ID.
      gFarmBaseID=kbUnitGetBaseID(unit);
      //Make a new breakdown.
      int numFarmPlans=aiPlanGetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeFarm);
      aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFarm, numFarmPlans, 100, 1.0, gFarmBaseID);
   }
   else
   {
      //If there are no other bases without settlements... stop farming.
      gFarmBaseID=-1;
      aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeFarm, 0);
   }
}

//==============================================================================
// RULE: startLandScouting
//
// grabs the first scout in the scout list and starts scouting with it.
//==============================================================================
rule startLandScouting
   minInterval 1
   active
{
   //If no scout, go away.
   if (gLandScout == -1)
   {
      xsDisableSelf();
      return;
   }

   if (cMyCulture == cCultureAtlantean)
      return;     // Atlanteans use special low-pri explore plans with pauses for oracle LOS.

   //Land based Scouting.
	gLandExplorePlanID=aiPlanCreate("Explore_Land", cPlanExplore);
   if (gLandExplorePlanID >= 0)
   {
      aiPlanAddUnitType(gLandExplorePlanID, gLandScout, 1, 1, 1);

      aiPlanSetEscrowID(gLandExplorePlanID, cEconomyEscrowID);

//      int oneStopPath = kbPathCreate("Start scout");
//      vector firstStop = kbGetTownLocation();
//      firstStop = firstStop + (kbBaseGetFrontVector(cMyID,kbBaseGetMainID(cMyID))*50);
      
//      kbPathAddWaypoint(oneStopPath, firstStop);
//      aiPlanSetWaypoints(gLandExplorePlanID, oneStopPath);
      aiPlanSetVariableFloat(gLandExplorePlanID, cExplorePlanLOSMultiplier, 0, 1.7);
      aiPlanSetVariableBool(gLandExplorePlanID, cExplorePlanDoLoops, 0, true);
      aiPlanSetVariableInt(gLandExplorePlanID, cExplorePlanNumberOfLoops, 0, 2);
      aiPlanSetInitialPosition(gLandExplorePlanID, kbBaseGetLocation(cMyID,kbBaseGetMainID(cMyID)));
      
      //Don't loop as egyptian.
      if (cMyCulture == cCultureEgyptian)
         aiPlanSetVariableBool(gLandExplorePlanID, cExplorePlanDoLoops, 0, false);

      aiPlanSetVariableBool(gLandExplorePlanID, cExplorePlanCanBuildLOSProto, 0, true);

      aiPlanSetActive(gLandExplorePlanID);
   }

   //Go away now.
   xsDisableSelf();
}

//==============================================================================
// RULE: autoBuildOutpost
//
// Restrict Egyptians from building outposts until they have a temple.
//==============================================================================
rule autoBuildOutpost
   minInterval 10
   inactive // Disabled because I'm starting it in startLandScouting, above
{
   if ((gLandScout == -1) || (cMyCulture != cCultureEgyptian))
   {
      xsDisableSelf();
      return;
   }
   if (getUnit(cUnitTypeTemple) == -1)
      return;

   aiPlanSetVariableBool(gLandExplorePlanID, cExplorePlanCanBuildLOSProto, 0, true);
   xsDisableSelf();
}

//==============================================================================
// RULE: airScouting
//
// scout with a flying scout.
//==============================================================================
rule airScouting
   minInterval 1
   inactive
{
   //Stop this if there are no flying scout.
   if (gAirScout == -1)
   {
      aiEcho("No Air scout specified.  Turning off air scout rule");
      xsDisableSelf();
      return;
   }

   //Maintain 1 air scout.
   createSimpleMaintainPlan(gAirScout, gMaintainNumberAirScouts, true, -1);

   //Create a progression to the air scout.
   int pid=aiPlanCreate("AirScoutProgression", cPlanProgression);
	if (pid >= 0)
	{ 
      aiEcho("Creating air scout progression.");
      aiPlanSetVariableInt(pid, cProgressionPlanGoalUnitID, 0, gAirScout);
		aiPlanSetDesiredPriority(pid, 100);
		aiPlanSetEscrowID(pid, cEconomyEscrowID);
		aiPlanSetActive(pid);
	}
   else
      aiEcho("Could not create train air scout plan.");

   //Once we have unit to scout with, set it in motion.
   int exploreID=aiPlanCreate("Explore_Air", cPlanExplore);
	if (exploreID >= 0)
	{
		aiEcho("Setting up air explore plan.");
      aiPlanAddUnitType(exploreID, gAirScout, 1, 1, 1);
      aiPlanSetVariableBool(exploreID, cExplorePlanDoLoops, 0, false);
		aiPlanSetActive(exploreID);
      aiPlanSetEscrowID(exploreID, cEconomyEscrowID);
	}
   else
      aiEcho("Could not create air explore plan.");

   //Go away.
   xsDisableSelf();
}


//==============================================================================
// econAge2Handler
//==============================================================================
void econAge2Handler(int age=1)
{
   aiEcho("Economy Age "+age+".");
   
   // Start early settlement monitor if not already active (vinland, team mig, nomad)
   xsEnableRule("buildSettlementsEarly");

   //Start up air scouting.
   airScouting();
   //Re-enable buildHouse.
   xsEnableRule("buildHouse");
   //Fire up opportunities.
   xsEnableRule("opportunities");

   //Farming is worthless without plow, get it first
	int plowPlanID=aiPlanCreate("getPlow", cPlanProgression);
	if (plowPlanID != 0)
   {
      aiPlanSetVariableInt(plowPlanID, cProgressionPlanGoalTechID, 0, cTechPlow);
	   aiPlanSetDesiredPriority(plowPlanID, 100);      // Do it ASAP!
	   aiPlanSetEscrowID(plowPlanID, cEconomyEscrowID);
	   aiPlanSetActive(plowPlanID);
   }
   //Make plan to get husbandry unless you're Atlantean
   if (cMyCulture != cCultureAtlantean)
   {
	   int husbandryPlanID=aiPlanCreate("getHusbandry", cPlanProgression);
	   if (husbandryPlanID != 0)
      {
         aiPlanSetVariableInt(husbandryPlanID, cProgressionPlanGoalTechID, 0, cTechHusbandry);
	      aiPlanSetDesiredPriority(husbandryPlanID, 25);
	      aiPlanSetEscrowID(husbandryPlanID, cEconomyEscrowID);
	      aiPlanSetActive(husbandryPlanID);
      }
   }
   else  // Turn on the settlement rule
      xsEnableRule("buildSettlements");
   
   // Transports
   if (gTransportMap == true) 
   {
	   int enclosedDeckID=aiPlanCreate("getEnclosedDeck", cPlanProgression);
	   if (enclosedDeckID != 0)
      {
         aiPlanSetVariableInt(enclosedDeckID, cProgressionPlanGoalTechID, 0, cTechEnclosedDeck);
	      aiPlanSetDesiredPriority(enclosedDeckID, 60);      
	      aiPlanSetEscrowID(enclosedDeckID, cEconomyEscrowID);
	      aiPlanSetActive(enclosedDeckID);
      }
   }

   //Hunting dogs.
   int huntingDogsPlanID=aiPlanCreate("getHuntingDogs", cPlanProgression);
	if (huntingDogsPlanID != 0)
   {
      aiPlanSetVariableInt(huntingDogsPlanID, cProgressionPlanGoalTechID, 0, cTechHuntingDogs);
	   aiPlanSetDesiredPriority(huntingDogsPlanID, 25);
	   aiPlanSetEscrowID(huntingDogsPlanID, cEconomyEscrowID);
	   aiPlanSetActive(huntingDogsPlanID);
   }

   // Fishing
   if (gFishing == true) 
   {
	   int purseSeineID=aiPlanCreate("getPurseSeine", cPlanProgression);
	   if (purseSeineID != 0)
      {
         aiPlanSetVariableInt(purseSeineID, cProgressionPlanGoalTechID, 0, cTechPurseSeine);
	      aiPlanSetDesiredPriority(purseSeineID, 45);      
	      aiPlanSetEscrowID(purseSeineID, cEconomyEscrowID);
	      aiPlanSetActive(purseSeineID);
      }
   }


   if ( (aiGetGameMode() == cGameModeDeathmatch) || (aiGetGameMode() == cGameModeLightning) )  // Add an emergency armory
   {
      if (cMyCulture == cCultureAtlantean)
      {
         createSimpleBuildPlan(cUnitTypeArmory, 1, 100, false, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 2);
         createSimpleBuildPlan(cUnitTypeManor, 3, 95, false, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         createSimpleBuildPlan(cUnitTypeArmory, 1, 100, false, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 3);
         createSimpleBuildPlan(cUnitTypeHouse, 6, 95, false, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 2);
      }
   }

   // Set escrow caps
   kbEscrowSetCap( cEconomyEscrowID, cResourceFood, 800.0);    // Age 3
   kbEscrowSetCap( cEconomyEscrowID, cResourceWood, 200.0);
   kbEscrowSetCap( cEconomyEscrowID, cResourceGold, 500.0);    // Age 3
   kbEscrowSetCap( cEconomyEscrowID, cResourceFavor, 30.0);
   kbEscrowSetCap( cMilitaryEscrowID, cResourceFood, 100.0);
   kbEscrowSetCap( cMilitaryEscrowID, cResourceWood, 200.0);   // Towers
   kbEscrowSetCap( cMilitaryEscrowID, cResourceGold, 200.0);   // Towers
   kbEscrowSetCap( cMilitaryEscrowID, cResourceFavor, 30.0);
}


rule getFortifiedTownCenter
inactive
minInterval 34
{
   //Get FTC if we already have 3 settlements, or immediately if no unclaimed settlements, or DM
   if (aiGetGameMode() != cGameModeDeathmatch)    // If not DM
   {
      if (kbUnitCount(0, cUnitTypeAbstractSettlement) > 0)
         if (kbUnitCount(cMyID, cUnitTypeAbstractSettlement) < 3)
            return;     // Quit if settlements remain and we don't yet have 3
   }

   // We're in DM, or we have 3 settlements, or we don't see any unclaimed settlements
   int planID=aiPlanCreate("GetFTCUpgrade", cPlanProgression);
	if (planID >= 0)
	{ 
      aiPlanSetVariableInt(planID, cProgressionPlanGoalTechID, 0, cTechFortifyTownCenter);
		aiPlanSetDesiredPriority(planID, 75);
		aiPlanSetEscrowID(planID, cEconomyEscrowID);
		aiPlanSetActive(planID);
	}
   xsDisableSelf();
}


//==============================================================================
// econAge3Handler
//==============================================================================
void econAge3Handler(int age=0)
{
   aiEcho("Economy Age "+age+".");

   //Enable misc rules.
   xsEnableRule("buildHouse");
   xsEnableRule("buildSettlements");
   xsDisableRule("buildSettlementsEarly");
   xsEnableRule("relocateFarming");

 
   xsEnableRule("getFortifiedTownCenter");

/*
   if (cMyCulture == cCultureAtlantean)
   {
      //Get Milk Stones.
      int planID=aiPlanCreate("GetMilkStonesUpgrade", cPlanProgression);
	   if (planID >= 0)
	   { 
         aiPlanSetVariableInt(planID, cProgressionPlanGoalTechID, 0, cTechMilkStones);
		   aiPlanSetDesiredPriority(planID, 99);
		   aiPlanSetEscrowID(planID, cEconomyEscrowID);
		   aiPlanSetActive(planID);
	   }
   }
*/
      // Fishing
   if (gFishing == true) 
   {
	   int saltAmphoraID=aiPlanCreate("getSaltAmphora", cPlanProgression);
	   if (saltAmphoraID != 0)
      {
         aiPlanSetVariableInt(saltAmphoraID, cProgressionPlanGoalTechID, 0, cTechSaltAmphora);
	      aiPlanSetDesiredPriority(saltAmphoraID, 80);      
	      aiPlanSetEscrowID(saltAmphoraID, cEconomyEscrowID);
	      aiPlanSetActive(saltAmphoraID);
      }
   }



   if ((aiGetGameMode() == cGameModeDeathmatch) || (aiGetGameMode() == cGameModeLightning))   // Add an emergency market
   {

      if (cMyCulture == cCultureAtlantean)
      {
         createSimpleBuildPlan(cUnitTypeMarket, 1, 100, false, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 2);
         gExtraMarket = true; // Set the global so we know to look for SECOND market before trading.       
         createSimpleBuildPlan(cUnitTypeManor, 1, 95, false, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         createSimpleBuildPlan(cUnitTypeMarket, 1, 100, false, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 5);
         gExtraMarket = true; // Set the global so we know to look for SECOND market before trading.       
         createSimpleBuildPlan(cUnitTypeHouse, 2, 95, false, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
      }
   }

   //Enable gatherer upgrades.
   xsEnableRule("getNextGathererUpgrade");

   // Set escrow caps
   kbEscrowSetCap( cEconomyEscrowID, cResourceFood, 1000.0);    // Age 4
   kbEscrowSetCap( cEconomyEscrowID, cResourceWood, 400.0);     // Settlements, upgrades
   kbEscrowSetCap( cEconomyEscrowID, cResourceGold, 1000.0);    // Age 4
   kbEscrowSetCap( cEconomyEscrowID, cResourceFavor, 40.0);
   kbEscrowSetCap( cMilitaryEscrowID, cResourceFood, 400.0);
   kbEscrowSetCap( cMilitaryEscrowID, cResourceWood, 400.0);   
   kbEscrowSetCap( cMilitaryEscrowID, cResourceGold, 400.0);   
   kbEscrowSetCap( cMilitaryEscrowID, cResourceFavor, 40.0);

   kbBaseSetMaximumResourceDistance(cMyID, kbBaseGetMainID(cMyID), 85.0);    
}

//==============================================================================
// econAge4Handler
//==============================================================================
void econAge4Handler(int age=0)
{
   aiEcho("Economy Age "+age+".");
   xsEnableRule("buildHouse");
   xsEnableRule("randomUpgrader");
   int numBuilders = 0;
   int bigBuildingType = 0;
   int littleBuildingType = 0;
   if (aiGetGameMode() == cGameModeDeathmatch)     // Add 3 extra big buildings and 6 little buildings
   {
      switch(cMyCulture)
      {
         case cCultureGreek:
            {
               bigBuildingType = cUnitTypeFortress;
               numBuilders = 3;
               createSimpleBuildPlan(cUnitTypeBarracks, 2, 90, true, false, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
               createSimpleBuildPlan(cUnitTypeStable, 2, 90, true, false, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
               createSimpleBuildPlan(cUnitTypeArcheryRange, 2, 90, true, false, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
               break;
            }
         case cCultureEgyptian:
            {
               numBuilders = 5;
               createSimpleBuildPlan(cUnitTypeBarracks, 6, 90, true, false, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 2);
               bigBuildingType = cUnitTypeMigdolStronghold;
               break;
            }
         case cCultureNorse:
            {
               numBuilders = 2;
               createSimpleBuildPlan(cUnitTypeLonghouse, 6, 90, true, false, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
               bigBuildingType = cUnitTypeHillFort;
               break;
            }
         case cCultureAtlantean:
            {
               numBuilders = 1;
               createSimpleBuildPlan(cUnitTypeBarracksAtlantean, 6, 90, true, false, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
               bigBuildingType = cUnitTypePalace;
               break;
            }
      }
      createSimpleBuildPlan(bigBuildingType, 3, 80, true, false, cMilitaryEscrowID, kbBaseGetMainID(cMyID), numBuilders);
   }


   // Set escrow caps tighter
   kbEscrowSetCap( cEconomyEscrowID, cResourceFood, 300.0);    
   kbEscrowSetCap( cEconomyEscrowID, cResourceWood, 300.0);    
   kbEscrowSetCap( cEconomyEscrowID, cResourceGold, 300.0);    
   kbEscrowSetCap( cEconomyEscrowID, cResourceFavor, 40.0);
   kbEscrowSetCap( cMilitaryEscrowID, cResourceFood, 300.0);
   kbEscrowSetCap( cMilitaryEscrowID, cResourceWood, 300.0);   
   kbEscrowSetCap( cMilitaryEscrowID, cResourceGold, 300.0);   
   kbEscrowSetCap( cMilitaryEscrowID, cResourceFavor, 40.0);

}

//==============================================================================
// initEcon
//
// setup the initial Econ stuff.
//==============================================================================
void initEcon()
{
   aiEcho("Economy Init.");

   //Set our update resource handler.
   aiSetUpdateResourceEventHandler("updateResourceHandler");

   //Set up auto-gather escrows.
   aiSetAutoGatherEscrowID(cEconomyEscrowID);
   aiSetAutoFarmEscrowID(cEconomyEscrowID);
	
   //Distribute the resources we have.
   kbEscrowAllocateCurrentResources();

   //Set our bases.
   gFarmBaseID=kbBaseGetMainID(cMyID);
   gGoldBaseID=kbBaseGetMainID(cMyID);
   gWoodBaseID=kbBaseGetMainID(cMyID);
	
   //Make a plan to manage the villager population.
   gCivPopPlanID=aiPlanCreate("civPop", cPlanTrain);
   if (gCivPopPlanID >= 0)
   {
      //Get our mainline villager PUID.
      int gathererPUID=gGatherer;

      aiPlanSetVariableInt(gCivPopPlanID, cTrainPlanUnitType, 0, gathererPUID);
      //Train off of economy escrow.
      aiPlanSetEscrowID(gCivPopPlanID, cEconomyEscrowID);
      //Default to 10.
      aiPlanSetVariableInt(gCivPopPlanID, cTrainPlanNumberToMaintain, 0, 10);    // Default until reset by updateEM
      aiPlanSetVariableInt(gCivPopPlanID, cTrainPlanBuildFromType, 0, cUnitTypeAbstractSettlement);   // Abstract fixes Citadel problem
      aiPlanSetDesiredPriority(gCivPopPlanID, 97); // MK:  Changed priority 100->97 so that oxcarts and ulfsark reserves outrank villagers.
      aiPlanSetActive(gCivPopPlanID);
   }

	//Create a herd plan to gather all herdables that we ecounter.
   gHerdPlanID=aiPlanCreate("GatherHerdable Plan", cPlanHerd);
   if (gHerdPlanID >= 0)
   {
      aiPlanAddUnitType(gHerdPlanID, cUnitTypeHerdable, 0, 100, 100);
      if ((cRandomMapName != "vinlandsaga") && (cRandomMapName != "team migration"))
         aiPlanSetBaseID(gHerdPlanID, kbBaseGetMainID(cMyID));
      else
      {
         if (cMyCulture != cCultureNorse)
            aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypeGranary);  
         else
            aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypeOxCart);
         if (cMyCulture == cCultureAtlantean)
            aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypeAbstractVillager);  
      }
      aiPlanSetActive(gHerdPlanID);
   }

   // Set our target for early-age settlements, based on 2x boom and 1x econ bias.
   float score = 2.0 * (-1.0*cvRushBoomSlider);    // Minus one, we want the boom side
   score = score + (-1.0 * cvMilitaryEconSlider);
   aiEcho("Early settlement score is "+score);     // Range is -3 to +3

   if (score > 0)
      gEarlySettlementTarget = 2;
   if (score > 1.5)
      gEarlySettlementTarget = 3;
   aiEcho("Early settlement target is "+gEarlySettlementTarget);

   if ( (cvRandomMapName != "vinlandsaga") &&
        (cvRandomMapName != "nomad") &&
        (cvRandomMapName != "team migration") )
   {
      xsEnableRule("buildSettlementsEarly");    // Turn on monitor, otherwise it waits for age 2 handler
   }
}




rule setEarlyEcon    // Initial econ is set to all food, below.  This changes
                     // it to the food-heavy "starting" mix after we have 7 villagers (or 3 for Atlantea).
minInterval 5
active
{
   int gathererCount = kbUnitCount(cMyID, gGatherer, cUnitStateAlive);
   if ( cMyCulture == cCultureAtlantean)
      gathererCount = gathererCount * 3;
   gathererCount = gathererCount + kbUnitCount(cMyID, cUnitTypeDwarf, cUnitStateAlive);
   gathererCount = gathererCount + kbUnitCount(cMyID, kbTechTreeGetUnitIDTypeByFunctionIndex(cUnitFunctionFish, 0), cUnitStateAlive);
   if ( gathererCount < 7) 
      return;
   
   float foodGPct=aiPlanGetVariableFloat(gGatherGoalPlanID, cGatherGoalPlanGathererPct, cResourceFood);
   float woodGPct=aiPlanGetVariableFloat(gGatherGoalPlanID, cGatherGoalPlanGathererPct, cResourceWood);
   float goldGPct=aiPlanGetVariableFloat(gGatherGoalPlanID, cGatherGoalPlanGathererPct, cResourceGold);
   float favorGPct=aiPlanGetVariableFloat(gGatherGoalPlanID, cGatherGoalPlanGathererPct, cResourceFavor);
   aiSetResourceGathererPercentage(cResourceFood, foodGPct, false, cRGPScript);
   aiSetResourceGathererPercentage(cResourceWood, woodGPct, false, cRGPScript);
   aiSetResourceGathererPercentage(cResourceGold, goldGPct, false, cRGPScript);
   aiSetResourceGathererPercentage(cResourceFavor, favorGPct, false, cRGPScript);
   aiNormalizeResourceGathererPercentages(cRGPScript);

   aiEcho("Setting normal gatherer distribution.");

   xsDisableSelf();
   xsEnableRule("econForecastAge1Mid");
}

//==============================================================================
// postInitEcon
//==============================================================================
void postInitEcon()
{
   aiEcho("Post Economy Init.");

   //Set the RGP weights.  Script in charge.
   aiPlanSetVariableFloat(gGatherGoalPlanID, cGatherGoalPlanScriptRPGPct, 0, 1.0);
   aiPlanSetVariableFloat(gGatherGoalPlanID, cGatherGoalPlanCostRPGPct, 0, 0.0);
   aiSetResourceGathererPercentageWeight(cRGPScript, 1.0);
   aiSetResourceGathererPercentageWeight(cRGPCost, 0.0);

   //Setup AI Cost weights.
   kbSetAICostWeight(cResourceFood, aiPlanGetVariableFloat(gGatherGoalPlanID, cGatherGoalPlanResourceCostWeight, cResourceFood));
   kbSetAICostWeight(cResourceWood, aiPlanGetVariableFloat(gGatherGoalPlanID, cGatherGoalPlanResourceCostWeight, cResourceWood));
   kbSetAICostWeight(cResourceGold, aiPlanGetVariableFloat(gGatherGoalPlanID, cGatherGoalPlanResourceCostWeight, cResourceGold));
   kbSetAICostWeight(cResourceFavor, aiPlanGetVariableFloat(gGatherGoalPlanID, cGatherGoalPlanResourceCostWeight, cResourceFavor));

   //Set initial gatherer percentages.
   float foodGPct=aiPlanGetVariableFloat(gGatherGoalPlanID,0, cResourceFood);    
   float woodGPct=aiPlanGetVariableFloat(gGatherGoalPlanID, 0, cResourceWood);   
   float goldGPct=aiPlanGetVariableFloat(gGatherGoalPlanID, 0, cResourceGold);   
   float favorGPct=aiPlanGetVariableFloat(gGatherGoalPlanID, 0, cResourceFavor);
   aiSetResourceGathererPercentage(cResourceFood, 1.0, false, cRGPScript);    // Changed these to 100% food early then
   aiSetResourceGathererPercentage(cResourceWood, 0.0, false, cRGPScript);    // the setEarlyEcon rule above will set the 
   aiSetResourceGathererPercentage(cResourceGold, 0.0, false, cRGPScript);    // former "initial" values once we have 9 (or 3 atlantean) gatherers.
   aiSetResourceGathererPercentage(cResourceFavor, 0.0, false, cRGPScript);
   aiNormalizeResourceGathererPercentages(cRGPScript);

   //Set up the initial resource break downs.
   int numFoodEasyPlans=aiPlanGetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeEasy);
   int numFoodHuntAggressivePlans=aiPlanGetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHuntAggressive);
   int numFishPlans=aiPlanGetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeFish);
   int numWoodPlans=aiPlanGetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumWoodPlans, 0);
   int numGoldPlans=aiPlanGetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumGoldPlans, 0);
   int numFavorPlans=aiPlanGetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFavorPlans, 0);
	aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeEasy, numFoodEasyPlans, 100, 1.0, kbBaseGetMainID(cMyID));
   aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHuntAggressive, numFoodHuntAggressivePlans, 90, 0.0, kbBaseGetMainID(cMyID));  // MK: Set from 1.0 to 0.0
   aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFish, numFishPlans, 100, 1.0, kbBaseGetMainID(cMyID));
   if (cMyCulture == cCultureEgyptian)
   {
      aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, numWoodPlans, 50, 1.0, kbBaseGetMainID(cMyID));
	   aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, numGoldPlans, 55, 1.0, kbBaseGetMainID(cMyID));
   }
   else
   {
      aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, numWoodPlans, 55, 1.0, kbBaseGetMainID(cMyID));
	   aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, numGoldPlans, 50, 1.0, kbBaseGetMainID(cMyID));
   }
   aiSetResourceBreakdown(cResourceFavor, cAIResourceSubTypeEasy, numFavorPlans, 40, 1.0, kbBaseGetMainID(cMyID));
}


//==============================================================================
// RULE: fishing
//==============================================================================
rule fishing
   minInterval 30
   inactive
{
   //Removed check for water map, rule is now only activated on water or unknown maps.

   if ((cRandomMapName == "river styx"))
   {
      aiEcho("Not going to explore water or fish on this map.");
		xsDisableSelf();
      return;
   }

	//Don't do anything until we  have our temple up.
   //MK: Disbling this, we should be able to handle it.  if ( kbUnitCount(cMyID, cUnitTypeAbstractTemple, cUnitStateAliveOrBuilding) <= 0)
   //   return;

	//Get the closest water area.  if there isn't one, we can't fish.
	static int areaID=-1;
	if (areaID == -1)
		areaID=kbAreaGetClosetArea(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)), cAreaTypeWater);
	if (areaID == -1)
	{
		aiEcho("Can't fish on this map, no water.");
		xsDisableSelf();
		return;
	}
aiEcho("Closest water area is "+areaID+", centered at "+kbAreaGetCenter(areaID));
	
   //Don't fish until we're setup for wood.
//   if (cMyCulture != cCultureAtlantis)
//	   if (kbSetupForResource(kbBaseGetMainID(cMyID), cResourceWood, 25.0, 600) == false)  // Do we have 600 wood within 25 meters?
//         return;
   //Get our fish gatherer.
	int fishGatherer=kbTechTreeGetUnitIDTypeByFunctionIndex(cUnitFunctionFish,0);

	//Create the fish plan.
	int fishPlanID=aiPlanCreate("FishPlan", cPlanFish);
	if (fishPlanID >= 0)
	{
		aiEcho("Starting up the fishing plan.  Will fish when I find fish.");
      aiPlanSetDesiredPriority(fishPlanID, 52);
		aiPlanSetVariableVector(fishPlanID, cFishPlanLandPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
		//If you don't explicitly set the water point, the plan will find one for you.
aiPlanSetVariableVector(fishPlanID, cFishPlanWaterPoint, 0, kbAreaGetCenter(areaID));
      aiPlanSetVariableBool(fishPlanID, cFishPlanAutoTrainBoats, 0, true);
		aiPlanSetEscrowID(fishPlanID, cEconomyEscrowID);
		aiPlanAddUnitType(fishPlanID, fishGatherer, 2, gNumBoatsToMaintain, gNumBoatsToMaintain);
aiPlanSetVariableFloat(fishPlanID, cFishPlanMaximumDockDist, 0, 500.0);
      gFishing = true;
		aiPlanSetActive(fishPlanID);
	}
   aiPlanSetVariableInt(gGatherGoalPlanID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeFish, 1);

   //Build a dock in water, so we can scout.
/* MK:  Disabled, the fishing plan will build a dock.
   int buildDock=aiPlanCreate("BuildDock", cPlanBuild);
   if (buildDock >= 0)
   {
      aiEcho("Building dock for scouting.");
      //BP Type and Priority.
      aiPlanSetVariableInt(buildDock, cBuildPlanBuildingTypeID, 0, cUnitTypeDock);
      aiPlanSetDesiredPriority(buildDock, 100);
      aiPlanSetVariableVector(buildDock, cBuildPlanDockPlacementPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
      aiPlanSetVariableVector(buildDock, cBuildPlanDockPlacementPoint, 1, kbAreaGetCenter(areaID));
      aiPlanAddUnitType(buildDock, gBuilder, 1, 1, 1);
      aiPlanSetEscrowID(buildDock, cEconomyEscrowID);
      aiPlanSetActive(buildDock);
   }
*/

//Hack-o-rific test...move the scouting unit directly over there to find water ASAP
   aiEcho("Leading scout to water.");
   int scout = findUnit(cMyID, cUnitStateAlive, gLandScout);
   if (scout >= 0)
      aiTaskUnitMove(scout, kbAreaGetCenter(areaID));

   gHouseAvailablePopRebuild = gHouseAvailablePopRebuild + 5;
   aiEcho("House rebuild is now "+gHouseAvailablePopRebuild);

   //Make a plan to explore with the water scout.
	int waterExploreID=aiPlanCreate("Explore_Water", cPlanExplore);
	if (waterExploreID >= 0)
	{
		aiEcho("Creating water explore plan.");
      aiPlanAddUnitType(waterExploreID, gWaterScout, 1, 1, 1);
		aiPlanSetDesiredPriority(waterExploreID, 100);
      aiPlanSetVariableBool(waterExploreID, cExplorePlanDoLoops, 0, false);
      aiPlanSetActive(waterExploreID);
      aiPlanSetEscrowID(cEconomyEscrowID);
	}
	xsDisableSelf();
}

//==============================================================================
// RULE: buildHouse
//==============================================================================
rule buildHouse
   minInterval 11
   active
{
   int houseProtoID = cUnitTypeHouse;
   if (cMyCulture == cCultureAtlantean)
       houseProtoID = cUnitTypeManor;
	if (iAmNative())
		houseProtoID = cUnitTypeHouseAmericanNative;

	//Don't build another house if we've got at least gHouseAvailablePopRebuild open pop slots.
   if (kbGetPop()+gHouseAvailablePopRebuild < kbGetPopCap())
      return;

   //If we have any houses that are building, skip.
   if (kbUnitCount(cMyID, houseProtoID, cUnitStateBuilding) > 0)
      return;
   
	//If we already have gHouseBuildLimit houses, we shouldn't build anymore.
   if (gHouseBuildLimit != -1)
   {
      int numberOfHouses=kbUnitCount(cMyID, houseProtoID, cUnitStateAliveOrBuilding);
      if (numberOfHouses >= gHouseBuildLimit)
         return;
   }

	//Get the current Age.
	int age=kbGetAge();
	//Limit the number of houses we build in each age.
	if (gAgeCapHouses == true)
   {
      if (age == 0)
	   {
		   if (numberOfHouses >= 2)
		   {
			   xsDisableSelf();
			   return;
		   }
	   }
   }

   //If we already have a house plan active, skip.
   if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, houseProtoID) > -1)
      return;

   //Over time, we will find out what areas are good and bad to build in.  Use that info here, because we want to protect houses.
	int planID=aiPlanCreate("BuildHouse", cPlanBuild);
   if (planID >= 0)
   {
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, houseProtoID);
      aiPlanSetVariableBool(planID, cBuildPlanInfluenceAtBuilderPosition, 0, true);
      aiPlanSetVariableFloat(planID, cBuildPlanInfluenceBuilderPositionValue, 0, 100.0);
      aiPlanSetVariableFloat(planID, cBuildPlanInfluenceBuilderPositionDistance, 0, 5.0);
      aiPlanSetVariableFloat(planID, cBuildPlanRandomBPValue, 0, 0.99);
      aiPlanSetDesiredPriority(planID, 100);

		int builderTypeID = gBuilder;
      if ((cMyCulture == cCultureNorse) && (iAmNative() == false))
         builderTypeID = cUnitTypeUlfsark;   // Exact match for land scout, so build plan can steal scout

		aiPlanAddUnitType(planID, builderTypeID, gBuildersPerHouse, gBuildersPerHouse, gBuildersPerHouse);
      aiPlanSetEscrowID(planID, cEconomyEscrowID);

      vector backVector = kbBaseGetBackVector(cMyID, kbBaseGetMainID(cMyID));

      float x = xsVectorGetX(backVector);
      float z = xsVectorGetZ(backVector);
      x = x * 40.0;
      z = z * 40.0;

      backVector = xsVectorSetX(backVector, x);
      backVector = xsVectorSetZ(backVector, z);
      backVector = xsVectorSetY(backVector, 0.0);
      vector location = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));
      int areaGroup1 = kbAreaGroupGetIDByPosition(location);   // Base area group
      location = location + backVector;
      int areaGroup2 = kbAreaGroupGetIDByPosition(location);   // Back vector area group
      if (areaGroup1 != areaGroup2)
         location = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));   // Reset to area center if back is in wrong area group

      // Hack to test norse scout-building if only one ulfsark exists
      if ( (cMyCulture == cCultureNorse) && ( kbUnitCount(cMyID, cUnitTypeUlfsark, cUnitStateAlive) == 1 ) 
         && (aiPlanGetLocation(gLandExplorePlanID) != cInvalidVector) )
      {
         location = aiPlanGetLocation(gLandExplorePlanID);
         aiPlanSetBaseID(planID, -1);
         aiPlanSetVariableInt(planID, cBuildPlanAreaID, 0, kbAreaGetIDByPosition(location));
      }
      else
         aiPlanSetBaseID(planID, kbBaseGetMainID(cMyID));   // Move this back up to block of aiPlanSets if we kill the hack
      // end hack

      aiPlanSetVariableVector(planID, cBuildPlanInfluencePosition, 0, location);
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionDistance, 0, 20.0);
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionValue, 0, 1.0);

      aiPlanSetActive(planID);
   }
}

//==============================================================================
// RULE: buildSettlements
//==============================================================================
rule buildSettlements
   minInterval 10
   inactive
{
	if (kbGetAge() < cAge3)
	{
		xsDisableSelf();
		return;
	}
   //Figure out if we have any active BuildSettlements.
   int numberBuildSettlementGoals=aiGoalGetNumber(cGoalPlanGoalTypeBuildSettlement, cPlanStateWorking, true);
   int numberSettlements=getNumberUnits(cUnitTypeAbstractSettlement, cMyID, cUnitStateAlive);
   int numberSettlementsPlanned = numberSettlements + numberBuildSettlementGoals;

   if ( numberSettlementsPlanned >= cvMaxSettlements)
      return;        // Don't go over script limit

   if ( numberBuildSettlementGoals > 1)	// Allow 2 in progress, no more
		return;
   if (findASettlement() == false)
      return;
   
   if ( numberSettlements > 0 )  // Test for all the normal reasons to not build a settlement, unless we have none
   {
      int popCapBuffer=10;
      popCapBuffer = popCapBuffer + ((-1*cvRushBoomSlider)+1)*20;  // Add 0 for extreme rush, 40 for extreme boom
      int currentPopNeeds=kbGetPop();
      int adjustedPopCap=getSoftPopCap()-popCapBuffer;

      //Dont do this unless we need the pop
      if (currentPopNeeds < adjustedPopCap)
         return;
      

      //If we're on Easy and we have 3 settlements, go away.
      if ((aiGetWorldDifficulty() == cDifficultyEasy) && (numberSettlementsPlanned >= 3))
      {
         xsDisableSelf();
         return;
      }
   }



   //Don't get too many more than our human allies.
   int largestAllyCount=-1;
   for (i=1; < cNumberPlayers)
   {
      if (i == cMyID)
         continue;
      if(kbIsPlayerAlly(i) == false)
         continue;
      if(kbIsPlayerHuman(i) == false)     // MK:  Only worry about humans, no sense holding back for confused AI ally
         continue;
      int count=getNumberUnits(cUnitTypeAbstractSettlement, i, cUnitStateAliveOrBuilding);
      if(count > largestAllyCount)
         largestAllyCount=count;
   }
   //Never have more than 2 more settlements than any human ally.
   int difference=numberSettlementsPlanned-largestAllyCount;
   if ((difference > 2) && (largestAllyCount>=0))     // If ally exists and we have more than 2 more...quit
      return;

   //See if there is another human on my team.
   bool haveHumanTeammate=false;
   for (i=1; < cNumberPlayers)
   {
      if(i == cMyID)
         continue;
      //Find the human player
      if (kbIsPlayerHuman(i) != true)
         continue;

      //This player is a human ally and not resigned.
      if ((kbIsPlayerAlly(i) == true) && (kbIsPlayerResigned(i) == false))
      {
         haveHumanTeammate=true;
         break;
      }
   }
   if(haveHumanTeammate == true)
   {
      if (kbGetAge() == cAge3)
      {
         if (numberSettlementsPlanned > 4)
            return;
      }
      else if (kbGetAge() == cAge4)
      {
         if (numberSettlementsPlanned > 5)
            return;
      }
   }
   aiEcho("Creating another settlement goal.");

   int numBuilders = 3;
   if (cMyCulture == cCultureAtlantean)
      numBuilders = 1;
   //Else, do it.
   createBuildSettlementGoal("BuildSettlement", kbGetAge(), -1, kbBaseGetMainID(cMyID), numBuilders, gBuilder, true, 100);
}





//==============================================================================
// RULE: buildSettlementsEarly...age 1/2 handler
//==============================================================================
rule buildSettlementsEarly
   minInterval 10
   inactive
{
   //Figure out if we have any active BuildSettlements.
   int numberBuildSettlementGoals=aiGoalGetNumber(cGoalPlanGoalTypeBuildSettlement, cPlanStateWorking, true);
   int numberSettlements=getNumberUnits(cUnitTypeAbstractSettlement, cMyID, cUnitStateAlive);
   int numberSettlementsPlanned = numberSettlements + numberBuildSettlementGoals;

   if ( numberBuildSettlementGoals > 1)	// Allow 2 in progress, no more
		return;
   if (findASettlement() == false)
      return;
   
   if ( numberSettlementsPlanned >= gEarlySettlementTarget )
      return;     // We have or are building all we want

	aiEcho("cvRandomMapName = "+cvRandomMapName+", settlements = "+numberSettlements);
	if ( (cvRandomMapName == "nomad") && (numberSettlements == 0) )
		return;		// Skip if we're still in nomad startup mode

   aiEcho("Creating another early settlement goal.");

   int numBuilders = 3;
   if (cMyCulture == cCultureAtlantean)
      numBuilders = 1;
   //Else, do it, pri 85 to be below farming at 90.
   createBuildSettlementGoal("BuildSettlement", kbGetAge(), -1, kbBaseGetMainID(cMyID), numBuilders, gBuilder, true, 85);
}






//==============================================================================
// RULE: opportunities
//==============================================================================
rule opportunities
   minInterval 31
   inactive
   runImmediately
{
   float currentFood=kbResourceGet(cResourceFood);
   //float currentWood=kbResourceGet(cResourceWood);
   float currentGold=kbResourceGet(cResourceGold);
   //float currentFavor=kbResourceGet(cResourceFavor);
   if (currentFood > 500 && currentGold > 300)
      getNextGathererUpgrade();
}

//==============================================================================
// RULE: randomUpgrader
//
//==============================================================================
rule randomUpgrader
   minInterval 30
   active
   runImmediately
{
   static int id=0;
   //Don't do anything until we have some pop.
   int maxPop=kbGetPopCap();
   if (maxPop < 130)
      return;
   //If we still have some pop slots to fill, quit.
   int currentPop=kbGetPop();
   if ((maxPop-currentPop) > 20)
      return;

   //If we have lots of resources, get a random upgrade.
   float currentFood=kbResourceGet(cResourceFood);
   float currentWood=kbResourceGet(cResourceWood);
   float currentGold=kbResourceGet(cResourceGold);
   float currentFavor=kbResourceGet(cResourceFavor);
   if ((currentFood > 1000) && (currentWood > 1000) && (currentGold > 1000))
   {
      int upgradeTechID=kbTechTreeGetRandomUnitUpgrade();
      //Dont make another plan if we already have one.
      if (aiPlanGetIDByTypeAndVariableType(cPlanProgression, cProgressionPlanGoalTechID, upgradeTechID) != -1)
         return;

      //Make plan to get this upgrade.
	   int planID=aiPlanCreate("nextRandomUpgrade - "+id, cPlanProgression);
	   if (planID < 0)
         return;
      
	   aiPlanSetVariableInt(planID, cProgressionPlanGoalTechID, 0, upgradeTechID);
	   aiPlanSetDesiredPriority(planID, 25);
	   aiPlanSetEscrowID(planID, cEconomyEscrowID);
	   aiPlanSetActive(planID);
      aiEcho("randomUpgrader: successful in creating a progression to "+kbGetTechName(upgradeTechID));
	   id++;
   }
}


