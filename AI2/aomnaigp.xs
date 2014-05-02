//==============================================================================
// AoMNaiGP.xs   
//
// This is the basic logic behind the casting of the various god powers
// Although some are rule driven, much of the complex searches and casting logic
// is handled by the C++ code.
//==============================================================================
// *****************************************************************************
//
// An explanation of some of the plan types, etc. in this file:
//
// aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModel...
//   CombatDistance - This is the standard one.  The plan will get attached to an 
//   attack plan, and the attack plan performs a query, and when the number and 
//   type of enemy units you specify are within the specified distance of the 
//   attack plan's location, the god power will go off. 
//
//   CombatDistancePosition - *doesn't* get attached to an attack plan.  
//   You specify a position, and when the number and type of enemy units are within 
//   distance of that position, the power goes off.  This, for instance, could see 
//   if there are many enemy units around your town center. 
//
//   CombatDistanceSelf - this one's kind of particular.  It gets attached to an 
//   attack plan.  The query you specify in the setup determines the number and 
//   type of *friendly* units neccessary to satisfy the evaluation.  Addtionally, 
//   there must be at least 5 (currently hardcoded) enemy units within the distance 
//   value of the attack plan for it to be successful.  Then the power will go off.  
//   This is typicaly used for powers than improve friendly units, like bronze, 
//   flaming weapons, and eclipse.  
//
// 
//
// *****************************************************************************
//==============================================================================
//Globals.
extern int gCeaseFirePlanID=-1;

//==============================================================================
// findHuntableInfluence
//==============================================================================
vector findHuntableInfluence()
{
   vector townLocation=kbGetTownLocation();
   vector best=townLocation;
   float bestDistSqr=0.0;

   //Run a query.
   int queryID=kbUnitQueryCreate("Huntable Units");
   if (queryID < 0)
      return(best);

   kbUnitQueryResetData(queryID);
   kbUnitQueryResetResults(queryID);
   kbUnitQuerySetPlayerID(queryID, 0);
   kbUnitQuerySetUnitType(queryID, cUnitTypeHuntable);
   kbUnitQuerySetState(cUnitStateAlive);
   int numberFound=kbUnitQueryExecute(queryID);

   for (i=0; < numberFound)
   {
      vector position=kbUnitGetPosition(kbUnitQueryGetResult(queryID, i));
      float dx=xsVectorGetX(townLocation)-xsVectorGetX(position);
      float dz=xsVectorGetZ(townLocation)-xsVectorGetZ(position);

      float curDistSqr=((dx*dx) + (dz*dz));
      if (curDistSqr > bestDistSqr)
      {
         best=position;
         bestDistSqr=curDistSqr;
      }
   }

   return(best);
}

//==============================================================================
// setupGodPowerPlan
//==============================================================================
bool setupGodPowerPlan(int planID = -1, int powerProtoID = -1)
{
   if (planID == -1)
      return (false);
   if (powerProtoID == -1)
      return (false);

   aiPlanSetBaseID(planID, kbBaseGetMainID(cMyID));

   //-- setup prosperity
   //-- This sets up the plan to cast itself when there are 5 people working on gold
   if (powerProtoID == cPowerProsperity)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelWorkers);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableInt(planID, cGodPowerPlanResourceType, 0, cResourceGold);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelWorld);
      return (true);
   }

   //-- setup plenty
   //-- we want this to cast in our town when we have 20 or more workers in the world
   if (powerProtoID == cPowerPlenty)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelWorkers);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 20);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTown);
      //-- override the default building placement distance so that plenty has some room to cast
      //-- it is pretty big..
      aiPlanSetVariableFloat(planID, cGodPowerPlanBuildingPlacementDistance, 0, 100.0);
      return (true);
   }

   //-- setup the serpents power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters
   if (powerProtoID == cPowerPlagueofSerpents)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      return (true);  
   }

   //-- setup the lure power
   //-- cast this in your town as soon as we have more than 3 huntable resources found, and towards that huntable stuff if we know about it
   if (powerProtoID == cPowerLure)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 

      //-- create the query used for evaluation
      int queryID=kbUnitQueryCreate("Huntable Evaluation");
      if (queryID < 0)
         return (false);

      kbUnitQueryResetData(queryID);
      kbUnitQuerySetPlayerID(queryID, 0);
      kbUnitQuerySetUnitType(queryID, cUnitTypeHuntable);
      kbUnitQuerySetState(cUnitStateAlive);

      aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
      aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerID, 0, 0);

      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelQuery);
      aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerID, 0, 0);
      
      
      //-- now set up the targeting and the influences for targeting
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTown);

      //-- this one gets special influences (maybe)
      //-- set up from a simple query
      //-- we also prevent the default "back of town" placement
      aiPlanSetVariableInt(planID, cGodPowerPlanBPLocationPreference, 0, cBuildingPlacementPreferenceNone);
            
      vector v = findHuntableInfluence();
      aiPlanSetVariableVector(planID, cGodPowerPlanBPInfluence, 0, v);
      aiPlanSetVariableFloat(planID, cGodPowerPlanBPInfluenceValue, 0, 10.0);
      aiPlanSetVariableFloat(planID, cGodPowerPlanBPInfluenceDistance, 0, 100.0);
      return (true);  
   }

   //-- setup the pestilence power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 50 meters, and at least 3 buildings must be found
   //-- this works on buildings
   if (powerProtoID == cPowerPestilence)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 50.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 3);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitaryBuilding);
      return (true);  
   }

   //-- setup the bronze power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 10 meters
   if (powerProtoID == cPowerBronze) 
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelAttachedPlanLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 40.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      return (true);  
   }

   //-- setup the earthquake power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 40 meters
   if (powerProtoID == cPowerEarthquake)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,cGodPowerPlanDistance, 0, 40.0);
      aiPlanSetVariableInt(planID,  cGodPowerPlanUnitTypeID, 0, cUnitTypeAbstractSettlement);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 1);
      return (true);  
   }

   //-- setup Citadel
   //-- This sets up the plan to cast itself immediately
   if (powerProtoID == cPowerCitadel)
   {
     
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTownCenter);
      return (true);
   }

   //-- setup the dwarven mine
   //-- use this when we are going to gather (so we don't allow it to cast right now)
   if (powerProtoID == cPowerDwarvenMine)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTown);
      //-- set up the global
      gDwarvenMinePlanID = planID;
      //-- enable the monitoring rule
      xsEnableRule("rDwarvenMinePower");
      return (true);  
   }

    //-- setup the curse power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters
   if (powerProtoID == cPowerCurse)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      return (true);  
   }

   //-- setup the Eclipse power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 50 meters, and at least 5 archers must be found
   //-- this works on buildings
   if (powerProtoID == cPowerEclipse)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistanceSelf);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelWorld);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 2);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMythUnit);
      return (true);  
   }

   //-- setup the flaming weapons
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 10 meters
   if (powerProtoID == cPowerFlamingWeapons) 
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistanceSelf);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelUnit);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeLogicalTypeValidFlamingWeaponsTarget);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 10);
      return (true);  
   }

   //-- setup the Forest Fire power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 40 meters
   if (powerProtoID == cPowerForestFire)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,cGodPowerPlanDistance, 0, 40.0);
      aiPlanSetVariableInt(planID,  cGodPowerPlanUnitTypeID, 0, cUnitTypeAbstractSettlement);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      return (true);  
   }

   //-- setup the frost power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters
   if (powerProtoID == cPowerFrost)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 10);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      return (true);  
   }

   //-- setup the healing spring power
   //-- cast this within 50 meters of the military gather 
   if (powerProtoID == cPowerHealingSpring)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelMilitaryGatherPoint);
      aiPlanSetVariableFloat(planID, cGodPowerPlanBuildingPlacementDistance, 0, 75.0);
      return (true);  
   }

   //-- setup the lightening storm power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters
   if (powerProtoID == cPowerLightningStorm)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 10);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      return (true);  
   }

    //-- setup the locust swarm power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 50 meters, and at least 3 farms must be found
   //-- this works on buildings
   if (powerProtoID == cPowerLocustSwarm)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 30.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeAbstractFarm);
      return (true);  
   }

    //-- setup the Meteor power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters
   if (powerProtoID == cPowerMeteor)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 10);
      return (true);  
   }

   //-- setup the Nidhogg power
   //-- cast this in your town immediately
   if (powerProtoID == cPowerNidhogg)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTown);
      return (true);  
   }

    //-- setup the Restoration power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters
   if (powerProtoID == cPowerRestoration)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      return (true);  
   }

   //-- setup the Sentinel power
   //-- cast this in your town immediately
   if (powerProtoID == cPowerSentinel)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTownCenter);
      return (true);  
   }

    //-- setup the Ancestors power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters
   if (powerProtoID == cPowerAncestors)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      return (true);  
   }

    //-- setup the Fimbulwinter power
   //-- cast this in your town immediately
   if (powerProtoID == cPowerFimbulwinter)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelWorld);
      return (true);  
   }

   //-- setup the Tornado power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 100 meters
   if (powerProtoID == cPowerTornado)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 40.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      return (true);  
   }

   //-- setup Undermine
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 50 meters, and at least 3 wall segments must be found
   //-- this works on buildings
   if (powerProtoID == cPowerUndermine)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelUnit);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 50.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 3);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeAbstractWall);
      return (true);  
   }

   //-- setup the great hunt
   //-- this power makes use of the KBResource evaluation condition
   //-- to find the best huntable kb resource with more than 200 total food.
   if (powerProtoID == cPowerGreatHunt)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelKBResource);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);

      aiPlanSetVariableInt(planID,  cGodPowerPlanResourceType, 0, cResourceFood);
      aiPlanSetVariableInt(planID,  cGodPowerPlanResourceSubType, 0, cAIResourceSubTypeEasy);
      aiPlanSetVariableBool(planID,  cGodPowerPlanResourceFilterHuntable, 0, true);
      aiPlanSetVariableFloat(planID, cGodPowerPlanResourceFilterTotal, 0, 600.0);
      return (true);  
   }

   //-- setup the bolt power
   //-- cast this on the first unit with over 250 hit points
   if (powerProtoID == cPowerBolt)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
     
       //-- create the query used for evaluation
      queryID=kbUnitQueryCreate("Bolt Evaluation");
      if (queryID < 0)
         return (false);

      kbUnitQueryResetData(queryID);
      kbUnitQuerySetPlayerID(queryID, aiGetMostHatedPlayerID());
      kbUnitQuerySetUnitType(queryID, cUnitTypeMilitary);
      kbUnitQuerySetState(cUnitStateAlive);

      aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
      aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());

      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 1);
      aiPlanSetVariableFloat(planID, cGodPowerPlanQueryHitpointFilter, 0, 250.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelQuery);
      aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());

      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelUnit);
      return (true);  
   }

     //-- setup the spy power
   if (powerProtoID == cPowerSpy)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
     
       //-- create the query used for evaluation
      queryID=kbUnitQueryCreate("Spy Evaluation");
      if (queryID < 0)
         return (false);

      kbUnitQueryResetData(queryID);
      kbUnitQuerySetPlayerRelation(cPlayerRelationEnemy);
      kbUnitQuerySetUnitType(queryID, cUnitTypeAbstractVillager);
      kbUnitQuerySetState(cUnitStateAlive);

      aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
      aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerRelation, 0, cPlayerRelationEnemy);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 1);
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelQuery);
      aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerRelation, 0, cPlayerRelationEnemy);

      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelUnit);
      return (true);  
   }

      //-- setup the Son of Osiris
      if (powerProtoID == cPowerSonofOsiris)
      {
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
     
          //-- create the query used for evaluation
         queryID=kbUnitQueryCreate("Osiris Evaluation");
         if (queryID < 0)
            return (false);

         kbUnitQueryResetData(queryID);
         kbUnitQuerySetPlayerID(queryID, cMyID);
         kbUnitQuerySetUnitType(queryID, cUnitTypePharaoh);
         kbUnitQuerySetState(cUnitStateAlive);

         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
         aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 1);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelQuery);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerID, 0, cMyID);

         aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelUnit);

         //-- kill the empower plan and relic gather plans.
         aiPlanDestroy(gEmpowerPlanID);
         aiPlanDestroy(gRelicGatherPlanID);

         return (true);  
      }

   //-- setup the vision power
   if (powerProtoID == cPowerVision)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      //-- don't need visiblity to cast this one.
      aiPlanSetVariableBool(planID, cGodPowerPlanCheckVisibility, 0, false);
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
     
      vector vLoc = vector(-1.0, -1.0, -1.0);

      //-- calculate the location to vision
      //-- find the center of the map
      vector vCenter = kbGetMapCenter();
      vector vTC = kbGetTownLocation();
      float centerx = xsVectorGetX(vCenter);
      float centerz = xsVectorGetZ(vCenter);
      float xoffset =  centerx - xsVectorGetX(vTC);
      float zoffset =  centerz - xsVectorGetZ(vTC);

      //xoffset = xoffset * -1.0;
      //zoffset = zoffset * -1.0;

      centerx = centerx + xoffset;
      centerz = centerz + zoffset;

      //-- cast this on the newly created location (reflected across the center)
      vLoc = xsVectorSetX(vLoc, centerx);
      vLoc = xsVectorSetZ(vLoc, centerz);

      aiPlanSetVariableVector(planID, cGodPowerPlanTargetLocation, 0, vLoc);


      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      return (true);  
   }

    //-- setup the rain power to cast when we have at least 5 farms
   if (powerProtoID == cPowerRain)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelQuery);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelWorld);

      //-- create the query used for evaluation
      queryID=kbUnitQueryCreate("Rain Evaluation");
      if (queryID < 0)
         return (false);

      kbUnitQueryResetData(queryID);
      kbUnitQuerySetPlayerID(queryID, cMyID);
      kbUnitQuerySetUnitType(queryID, cUnitTypeFarm);
      kbUnitQuerySetState(cUnitStateAlive);

      aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
      aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerID, 0, cMyID);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);


      return (true);  
   }

   //-- setup Cease Fire
   //-- This sets up the plan to not cast itself
   //-- we also enable a rule that monitors the state of the player's main base
   //-- and waits until the base is under attack and has no defenders
   if (powerProtoID == cPowerCeaseFire)
   { 
      gCeaseFirePlanID = planID;
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelWorld);
      xsEnableRule("rCeaseFire");
      return (true);
   }


   //-- setup the Walking Woods power
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 10 meters
   if (powerProtoID == cPowerWalkingWoods) 
   {
      //-- basic plan type and eval model
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);

      //-- setup the nearby unit type to cast on
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelNearbyUnitType);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 1, cUnitTypeTree);

      //-- finish setup
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 40.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      return (true);  
   }

     
   //-- setup the Ragnorok Power
   //-- launch at 50 villagers
   if (powerProtoID == cPowerRagnorok)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
     
       //-- create the query used for evaluation
      queryID=kbUnitQueryCreate("Ragnorok Evaluation");
      if (queryID < 0)
         return (false);

      kbUnitQueryResetData(queryID);
      kbUnitQuerySetPlayerID(queryID, cMyID);
      kbUnitQuerySetUnitType(queryID, cUnitTypeAbstractVillager);
      kbUnitQuerySetState(cUnitStateAlive);

      aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 50);
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelQuery);
      aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerID, 0, cMyID);

      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelWorld);
      return (true);  
   }    
/* Duplicate of below
   //-- setup the deconstruct power
   //-- cast this on the first building with over 500 hit points
   if (powerProtoID == cPowerDeconstruction)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
     
       //-- create the query used for evaluation
      queryID=kbUnitQueryCreate("Deconstruction Evaluation");
      if (queryID < 0)
         return (false);

      kbUnitQueryResetData(queryID);
      kbUnitQuerySetPlayerID(queryID, aiGetMostHatedPlayerID());
      kbUnitQuerySetUnitType(queryID, cUnitTypeBuilding);
      kbUnitQuerySetState(cUnitStateAlive);

      aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
      aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());

      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 1);
      aiPlanSetVariableFloat(planID, cGodPowerPlanQueryHitpointFilter, 0, 500.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelQuery);
      aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());

      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelUnit);
      return (true);  
   }
*/

   // Set up the Gaia Forest power
   // Just fire and refire whenever we can, in the town.  This will keep a supply of fast-harvesting
   // wood in the well-protected zone around the player's town.
   if (powerProtoID == cPowerGaiaForest)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTown);
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);
   }

      // Set up the Thunder Clap power
   // Logic similar to bronze...look for 5+ enemy units within 30 meters of the attack plan's position
   if (powerProtoID == cPowerTremor)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
//      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelAttachedPlanLocation);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelNearbyUnitType);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 1, cUnitTypeMilitary);  // Var 1 is type to target on?
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 30.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);
   }



   // Set up the deconstruction power
   // Any building over 500 HP counts, cast it on building
   if (powerProtoID == cPowerDeconstruction)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
     
       //-- create the query used for evaluation
      queryID=kbUnitQueryCreate("Deconstruction Evaluation");
      if (queryID < 0)
         return (false);

      kbUnitQueryResetData(queryID);
      kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemy);
      kbUnitQuerySetUnitType(queryID, cUnitTypeLogicalTypeValidDeconstructionTarget);
      kbUnitQuerySetState(cUnitStateAlive);

      aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
 //     aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());

      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 1);
      aiPlanSetVariableFloat(planID, cGodPowerPlanQueryHitpointFilter, 0, 500.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelQuery);
//      aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());

      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelUnit);      
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);
   }


   // Set up the Carnivora power
   // Exactly like Serpents
   if (powerProtoID == cPowerCarnivora)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
//      aiPlanSetVariableInt(planID,  cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);
   }

   // Set up the Spiders power
   // Can't be reactive because of time delay.  Would like to place it
   // on gold mines or markets, if we haven't already spidered that location
   //****For now, just copy carnivora
   if (powerProtoID == cPowerSpiders)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);
   }

   // Set up the heroize power
   // Any time we have a group of 8 or more military units
   if (powerProtoID == cPowerHeroize)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistanceSelf);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelWorld);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 8);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);
   }

   // Set up the chaos power
   // 12 enemy mil units within 30m of attack plan
   if (powerProtoID == cPowerChaos)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelAttachedPlanLocation);
//      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelNearbyUnitType);
//      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 1, cUnitTypeMilitary);  // Target on this type
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 30.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 12);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
         aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);
   }


   // Set up the Traitors power
   // Same as bolt, anything over 200 HP
   if (powerProtoID == cPowerTraitors)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
     
       //-- create the query used for evaluation
      queryID=kbUnitQueryCreate("Traitors Evaluation");
      if (queryID < 0)
         return (false);

      kbUnitQueryResetData(queryID);
      kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemy);
      kbUnitQuerySetUnitType(queryID, cUnitTypeMilitary);
      kbUnitQuerySetState(cUnitStateAlive);

      aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 1);
      aiPlanSetVariableFloat(planID, cGodPowerPlanQueryHitpointFilter, 0, 200.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelQuery);
      aiPlanSetVariableInt(planID, cGodPowerPlanQueryPlayerRelation, 0, cPlayerRelationEnemy);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelUnit);
      return (true);  
   }
   /*  Replaced 2003/05/08 MK
   if (powerProtoID == cPowerTraitors)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelNearbyUnitType);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 1, cUnitTypeMilitary);  // Target on this type
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 30.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 12);
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);
   }
   */

   // Set up the hesperides power
   // Near the military gather point, for good protection
   if (powerProtoID == cPowerHesperides)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelMilitaryGatherPoint);
      aiPlanSetVariableFloat(planID, cGodPowerPlanBuildingPlacementDistance, 0, 25.0);
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);
   }

   // Set up the implode power
   // Look for at least a dozen units, target it on a building (to be sure at least one exists)
   if (powerProtoID == cPowerImplode)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelNearbyUnitType);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 1, cUnitTypeBuilding);  // Target on this type
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 30.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeUnit);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 12);
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);
   }

   // Set up the tartarian gate power
   // Fire if >= 4 military buildings near my army...will kill my army, but may take out their center, too.
   if (powerProtoID == cPowerTartarianGate)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 40.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeFarm);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);
   }

   // Set up the vortex power
   // If there are at least 15 (count 'em, 15!) enemy military units in my town, panic
   if (powerProtoID == cPowerVortex)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true);
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistancePosition);
      aiPlanSetVariableVector(planID, cGodPowerPlanTargetLocation, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 30.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 15);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);
   }

   // The Natives
   // I suck at AI scripting...

   //-- Set up Healing building
   if (powerProtoID == cPowerANHealing1)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelMilitaryGatherPoint);
      aiPlanSetVariableFloat(planID, cGodPowerPlanBuildingPlacementDistance, 0, 75.0);
      return (true);  
   }

   if (powerProtoID == cPowerANHealing2)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelMilitaryGatherPoint);
      aiPlanSetVariableFloat(planID, cGodPowerPlanBuildingPlacementDistance, 0, 75.0);
      return (true);  
   }

   if (powerProtoID == cPowerANHealing3)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelMilitaryGatherPoint);
      aiPlanSetVariableFloat(planID, cGodPowerPlanBuildingPlacementDistance, 0, 75.0);
      return (true);  
   }

   //-- This could also be the healing building ^^
   if (powerProtoID == cPowerHeal1)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      return (true);  
   }

   if (powerProtoID == cPowerHeal2)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      return (true); 
   }

   if (powerProtoID == cPowerHeal3)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      return (true); 
   }

   //-- setup  Wiracocha GP
   //-- This sets up the plan to cast itself immediately
   if (powerProtoID == cPowerCreationoftheWorld)
   {
     
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTownCenter);
      return (true);
   }

   //-- setup Itzamna GP
   //-- This sets up the plan to cast itself immediately
   if (powerProtoID == cPowerDecisionoftheGods)
   {
     
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTownCenter);
      return (true);
   }

   //-- setup Huitzi GP
   //-- This sets up the plan to cast itself immediately
   if (powerProtoID == cPowerHuitzilopochtlisProtection)
   {
     
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTownCenter);
      return (true);
   }

   //-- setup Quilla GP
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters, and at least 5 Mythunits must be found
   //-- this works on buildings
   if (powerProtoID == cPowerSolarEclipse)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelAttachedPlanLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMythUnit);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
      return (true);  
   }

   //-- setup Mamacocha GP
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters
   if (powerProtoID == cPowerFlood)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 10);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      return (true);  
   }
    //-- setup Chak GP
    // EMPTY

    //-- setup Ah Puch GP
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters
   if (powerProtoID == cPowerCreationofDeath)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 18.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 10);
      aiPlanSetVariableBool(planID, cGodPowerPlanTownDefensePlan, 0, true);
      return (true);  
   }

   //-- setup Tlaloc GP
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 15 meters
   if (powerProtoID == cPowerNightFall) 
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistanceSelf);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelUnit);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeLogicalTypeValidFlamingWeaponsTarget);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 20);
      return (true);  
   }

   //-- setup Tonatiuh GP
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 15 meters
   if (powerProtoID == cPowerSunRise) 
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistanceSelf);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelUnit);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeLogicalTypeValidFlamingWeaponsTarget);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 20);
      return (true);  
   }

   //-- setup Illapa GP
   //-- This sets up the plan to cast itself immediately
   if (powerProtoID == cPowerWalkingBuilding)
   {
     
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTownCenter);
      return (true);
   }

   // setup Apu GP
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters
   if (powerProtoID == cPowerCreatingMountains)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID,  cGodPowerPlanUnitTypeID, 0, cUnitTypeAbstractSettlement);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 1);
      return (true);  
   }

   //-- setup Ix-Chel GP
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters
   if (powerProtoID == cPowerCreationoftheMoon)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 10);
      return (true);  
   }

   // setup Vacub Caquix GP
   // EMPTY

   // setup Tezcatlipoca GP
   // EMPTY

   // setup Chalchiuhtlicue GP
   // EMPTY

   // setup Pachamama GP
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 20 meters
   if (powerProtoID == cPowerPachamamasCreation)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,cGodPowerPlanDistance, 0, 20.0);
      aiPlanSetVariableInt(planID,  cGodPowerPlanUnitTypeID, 0, cUnitTypeAbstractSettlement);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 1);
      return (true);  
   }

   //-- setup Inti GP
   //-- this power will cast when it has a valid attack plan within the specified range
   //-- the attack plan is setup in the initializeAttack function  
   //-- the valid distance is 50 meters
   if (powerProtoID == cPowerSunBurst)
   {
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
      aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
      aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 50.0);
      aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeMilitary);
      aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 10);
      return (true);  
   }

   //-- setup Ek Chuah GP
   //-- This sets up the plan to cast itself immediately
   if (powerProtoID == cPowerBlessingofEkChuah)
   {
     
      aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
      aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelNone);
      aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTownCenter);
      return (true);
   }

   //-- setup Zipacna GP
   //EMPTY

   //-- setup Quetzalcoatl GP
   //EMPTY

   //-- setup Xipe Totec GP
   //EMPTY

   // Mamachocha GP
 //  if (powerProtoID == cPowerPachamamasMouth)
 //  {
 //     aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, true); 
 //     aiPlanSetVariableInt(planID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
 //     aiPlanSetVariableInt(planID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelLocation);
 //     aiPlanSetVariableFloat(planID,  cGodPowerPlanDistance, 0, 40.0);
  //    aiPlanSetVariableInt(planID, cGodPowerPlanUnitTypeID, 0, cUnitTypeFarm);
  //    aiPlanSetVariableInt(planID, cGodPowerPlanCount, 0, 5);
 //     aiPlanSetVariableBool(planID, cGodPowerPlanMultiCast, 0, true);
 //     return (true);
 //  }

   return (false);
}

//==============================================================================
// initGP - initialize the god power module
//==============================================================================
void initGodPowers(void)
{
   aiEcho("GP Init.");
}

//==============================================================================
// Age 1 GP Rule
//==============================================================================
rule rAge1FindGP
   minInterval 12
   active
{
	int id=aiGetGodPowerTechIDForSlot(0); 
	if (id == -1)
		return;

	gAge1GodPowerID=aiGetGodPowerProtoIDForTechID(id);

	//Create the plan.
	gAge1GodPowerPlanID=aiPlanCreate("Age1GodPower", cPlanGodPower);
	if (gAge1GodPowerPlanID == -1)
	{
	   //This is bad, and we most likely can never build a plan, so kill ourselves.
	   xsDisableSelf();
	   return;
	}

	aiPlanSetVariableInt(gAge1GodPowerPlanID,  cGodPowerPlanPowerTechID, 0, id);
	aiPlanSetDesiredPriority(gAge1GodPowerPlanID, 100);
	aiPlanSetEscrowID(gAge1GodPowerPlanID, -1);

   //Setup the god power based on the type.
   if (setupGodPowerPlan(gAge1GodPowerPlanID, gAge1GodPowerID) == false)
   {
      aiPlanDestroy(gAge1GodPowerPlanID);
      gAge1GodPowerID=-1;
      xsDisableSelf();
      return;
   }

   if (cvOkToUseAge1GodPower == true)
   	aiPlanSetActive(gAge1GodPowerPlanID);

	//Kill ourselves if we every make a plan.
	xsDisableSelf();
}


//==============================================================================
// Age 2 GP Rule
//==============================================================================
rule rAge2FindGP
   minInterval 12
   inactive
{
	//Figure out the age2 god power and create the plan.
	int id=aiGetGodPowerTechIDForSlot(1); 
	if (id == -1)
	  return;

	gAge2GodPowerID=aiGetGodPowerProtoIDForTechID(id);

	//Create the plan.
	gAge2GodPowerPlanID=aiPlanCreate("Age2GodPower", cPlanGodPower);
	if (gAge2GodPowerPlanID == -1)
   {
      //This is bad, and we most likely can never build a plan, so kill ourselves.
	   xsDisableSelf();
	   return;
   }

	aiPlanSetVariableInt(gAge2GodPowerPlanID, cGodPowerPlanPowerTechID, 0, id);
	aiPlanSetDesiredPriority(gAge2GodPowerPlanID, 100);
	aiPlanSetEscrowID(gAge2GodPowerPlanID, -1);

   //Setup the god power based on the type.
   if (setupGodPowerPlan(gAge2GodPowerPlanID, gAge2GodPowerID) == false)
   {
      aiPlanDestroy(gAge2GodPowerPlanID);
      gAge2GodPowerID = -1;
      xsDisableSelf();
      return;
   }

   aiEcho("initializing god power plan for age 2");
   if (cvOkToUseAge2GodPower == true)
      aiPlanSetActive(gAge2GodPowerPlanID);

	//Kill ourselves if we every make a plan.
	xsDisableSelf();
}


//==============================================================================
// Age 3 GP Rule
//==============================================================================
rule rAge3FindGP
   minInterval 12
   inactive
{
	//Figure out the age3 god power and create the plan.
	int id=aiGetGodPowerTechIDForSlot(2); 
	if (id == -1)
	  return;

	gAge3GodPowerID=aiGetGodPowerProtoIDForTechID(id);

	//Create the plan
	gAge3GodPowerPlanID=aiPlanCreate("Age3GodPower", cPlanGodPower);
	if (gAge3GodPowerPlanID == -1)
	{
       //This is bad, and we most likely can never build a plan, so kill ourselves.
	   xsDisableSelf();
	   return;
   }

	aiPlanSetVariableInt(gAge3GodPowerPlanID, cGodPowerPlanPowerTechID, 0, id);
	aiPlanSetDesiredPriority(gAge3GodPowerPlanID, 100);
	aiPlanSetEscrowID(gAge3GodPowerPlanID, -1);

   //Setup the god power based on the type.
   if (setupGodPowerPlan(gAge3GodPowerPlanID, gAge3GodPowerID) == false)
   {
      aiPlanDestroy(gAge3GodPowerPlanID);
      gAge3GodPowerID = -1;
      xsDisableSelf();
      return;
   }

   aiEcho("initializing god power plan for age 3");
   if (cvOkToUseAge3GodPower == true)
      aiPlanSetActive(gAge3GodPowerPlanID);

   //Kill ourselves if we every make a plan.
	xsDisableSelf();
}


//==============================================================================
// Age 4 GP Rule
//==============================================================================
rule rAge4FindGP
   minInterval 12
   inactive
{
	//Figure out the age4 god power and create the plan.
	int id = aiGetGodPowerTechIDForSlot(3); 
	if (id == -1)
	  return;

	gAge4GodPowerID=aiGetGodPowerProtoIDForTechID(id);

	//Create the plan.
	gAge4GodPowerPlanID=aiPlanCreate("Age4GodPower", cPlanGodPower);
	if (gAge4GodPowerPlanID == -1)
   {
      //This is bad, and we most likely can never build a plan, so kill ourselves.
	   xsDisableSelf();
	   return;
   }

	aiPlanSetVariableInt(gAge4GodPowerPlanID, cGodPowerPlanPowerTechID, 0, id);
	aiPlanSetDesiredPriority(gAge4GodPowerPlanID, 100);
	aiPlanSetEscrowID(gAge4GodPowerPlanID, -1);

   //Setup the god power based on the type.
   if (setupGodPowerPlan(gAge4GodPowerPlanID, gAge4GodPowerID) == false)
   {
      aiPlanDestroy(gAge4GodPowerPlanID);
      gAge4GodPowerID=-1;
      xsDisableSelf();
      return;
   }

   aiEcho("initializing god power plan for age 4");
   if (cvOkToUseAge4GodPower == true)
      aiPlanSetActive(gAge4GodPowerPlanID);

   //Kill ourselves if we every make a plan.
	xsDisableSelf();
	return;
}

//==============================================================================
// Cease Fire Rule
//==============================================================================
rule rCeaseFire
   minInterval 21
   inactive
{
   static int defCon=0;
   bool nowUnderAttack=kbBaseGetUnderAttack(cMyID, kbBaseGetMainID(cMyID));

   //Not in a state of alert.
   if (defCon == 0)
   {
      //Just get out if we are safe.
      if (nowUnderAttack == false)
         return;  
      //Up the alert level and come back later.
      defCon=defCon+1;
      return;
   }

   //If we are no longer under attack and below this point, then reset and get out.
   if (nowUnderAttack == false)
   {
      defCon=0;
      return;
   }

   //Otherwise handle the different alert levels.
   //Do we have any help in the area that we can use?
  //If we don't have a query ID, create it.
   static int allyQueryID=-1;
   if (allyQueryID < 0)
   {
      allyQueryID=kbUnitQueryCreate("AllyCount");
      //If we still don't have one, bail.
      if (allyQueryID < 0)
         return;
   }

   //Else, setup the query data.
   kbUnitQuerySetPlayerRelation(cPlayerRelationAlly);
   kbUnitQuerySetUnitType(allyQueryID, cUnitTypeMilitary);
   kbUnitQuerySetState(allyQueryID, cUnitStateAlive);
   //Reset the results.
   kbUnitQueryResetResults(allyQueryID);
   //Run the query. 
   int count=kbUnitQueryExecute(allyQueryID);

   //If there are still allies in the area, then just stay at this alert level.
   if (count > 0)
      return;

   //Defcon 2.  Cast the god power.
   aiPlanSetVariableBool(gCeaseFirePlanID, cGodPowerPlanAutoCast, 0, true); 
   xsDisableSelf();
}


//==============================================================================
// Unbuild Rule      
//==============================================================================
rule rUnbuild
   minInterval 12
   inactive
{

	//Create the plan.
	gUnbuildPlanID = aiPlanCreate("Unbuild", cPlanGodPower);
	if (gUnbuildPlanID == -1)
	{
	   //This is bad, and we most likely can never build a plan, so kill ourselves.
	   xsDisableSelf();
	   return;
	}

//	aiPlanSetVariableInt(gUnbuildPlanID,  cGodPowerPlanPowerTechID, 0, id);
	aiPlanSetDesiredPriority(gUnbuildPlanID, 100);
	aiPlanSetEscrowID(gUnbuildPlanID, -1);

   //Setup the plan.. 
   // these are first pass.. fix these eventually.. 
   aiPlanSetVariableBool(gUnbuildPlanID, cGodPowerPlanAutoCast, 0, true); 
   aiPlanSetVariableInt(gUnbuildPlanID,  cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelCombatDistance);
   aiPlanSetVariableInt(gUnbuildPlanID,  cGodPowerPlanQueryPlayerID, 0, aiGetMostHatedPlayerID());
//   aiPlanSetVariableInt(gUnbuildPlanID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelAttachedPlanLocation);
   aiPlanSetVariableInt(gUnbuildPlanID,  cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelUnbuild);
   aiPlanSetVariableFloat(gUnbuildPlanID,  cGodPowerPlanDistance, 0, 40.0);
   aiPlanSetVariableInt(gUnbuildPlanID, cGodPowerPlanUnitTypeID, 0, cUnitTypeLogicalTypeBuildingsNotWalls);
   aiPlanSetVariableInt(gUnbuildPlanID, cGodPowerPlanCount, 0, 1);


	aiPlanSetActive(gUnbuildPlanID);

	//Kill ourselves if we every make a plan.
	xsDisableSelf();
}

//==============================================================================
// Age 2 Handler
//==============================================================================
void gpAge2Handler(int age=1)
{
   xsEnableRule("rAge2FindGP");
}

//==============================================================================
// Age 3 Handler
//==============================================================================
void gpAge3Handler(int age=2)
{
	xsEnableRule("rAge3FindGP");  
}

//==============================================================================
// Age 4 Handler
//==============================================================================
void gpAge4Handler(int age=3)
{
	xsEnableRule("rAge4FindGP");
}

//==============================================================================
// Dwarven Mine Rule
//==============================================================================
rule rDwarvenMinePower
   minInterval 59
   inactive
{
   if (gDwarvenMinePlanID == -1)
   {
      xsDisableSelf();
      return;
   }

   //Are we in the third age yet??
   if (kbGetAge() < 2)
      return;

   //Are we gathering gold?  If so, then enable the gold mine to be cast.
   float fPercent=aiGetResourceGathererPercentage(cResourceGold, cRGPActual);
   if (fPercent <= 0.0)
      return;
       
   aiPlanSetVariableBool(gDwarvenMinePlanID, cGodPowerPlanAutoCast, 0, true);
   
   //Finished.
   gDwarvenMinePlanID=-1;
   xsDisableSelf();
}

//==============================================================================
// unbuildHandler
//==============================================================================
void unbuildHandler(void)
{
   xsEnableRule("rUnbuild");
}

//==============================================================================
// Titan Gate Rule
//==============================================================================
rule rPlaceTitanGate
   minInterval 12
   inactive
{

	//Figure out the age 5 (yes, 5) god power and create the plan.
	int id = aiGetGodPowerTechIDForSlot(4); 
	if (id == -1)
	  return;

	gAge5GodPowerID=aiGetGodPowerProtoIDForTechID(id);

	//Create the plan.
	gPlaceTitanGatePlanID = aiPlanCreate("PlaceTitanGate", cPlanGodPower);
	if (gPlaceTitanGatePlanID == -1)
	{
	   //This is bad, and we most likely can never build a plan, so kill ourselves.
	   xsDisableSelf();
	   return;
	}

	// Set the Base
	aiPlanSetBaseID(gPlaceTitanGatePlanID, kbBaseGetMainID(cMyID));

	aiPlanSetVariableInt(gPlaceTitanGatePlanID,  cGodPowerPlanPowerTechID, 0, id);
	aiPlanSetDesiredPriority(gPlaceTitanGatePlanID, 100);
	aiPlanSetEscrowID(gPlaceTitanGatePlanID, -1);

    //Setup the plan.. 
	aiPlanSetVariableBool(gPlaceTitanGatePlanID, cGodPowerPlanAutoCast, 0, true); 
	aiPlanSetVariableInt(gPlaceTitanGatePlanID, cGodPowerPlanEvaluationModel, 0, cGodPowerEvaluationModelWorkers);
	aiPlanSetVariableInt(gPlaceTitanGatePlanID, cGodPowerPlanCount, 0, 6);
	aiPlanSetVariableInt(gPlaceTitanGatePlanID, cGodPowerPlanTargetingModel, 0, cGodPowerTargetingModelTown);
	//-- override the default building placement distance so that plenty has some room to cast
	//-- it is pretty big..
	aiPlanSetVariableFloat(gPlaceTitanGatePlanID, cGodPowerPlanBuildingPlacementDistance, 0, 100.0);

	aiPlanSetActive(gPlaceTitanGatePlanID);

	//Kill ourselves if we ever make a plan.
	xsDisableSelf();
}
