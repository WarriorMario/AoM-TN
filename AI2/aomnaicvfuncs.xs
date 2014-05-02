// AoMNaiCVFunc.xs
//
// Control Variable function calls.
//
// This file contains functions that are used to change control variables after initialization.
// DO NOT change control variables directly after initialization (in setParameters(), or 
// occasionaly in setOverrides(), as directed in aomMKcv.xs.)  If you need to change
// a control variable after the start, look in this file for the appropriate function
// that changes it and does any necessary housekeeping.  For example, suppose you had set 
// cvMaxAge = cAge2 in setParameters() to keep the AI from reaching age 3.  If you wanted
// to remove that restriction at the 20 minute mark, it would be BAD to just add
// a rule with the line cvMaxAge = cAge4.  Instead, you'd look below, and add a line that 
// says setMaxAge(cAge4).
// 
// Functions are listed in alphabetic order

// cvDelayStart setting function
void setDelayStart(bool new = true)
{
   cvDelayStart = true;
   gStartTime = xsGetTime();
   xsEnableRule("age1Progress");
   init();
   xsEnableRuleGroup("startRules");
}



// cvMaxAge setting function.
void setMaxAge(int age = cAge4)
{
   cvMaxAge = age;

   if (kbGetAge() >= age)  // We're there or beyond, turn off the age upgrades
   {
         aiSetPauseAllAgeUpgrades(true);  
         aiEcho("Suspending age upgrades");
   }
   else
   {     // We're not at that age yet, turn off the pause if it was already set
      if (aiGetPauseAllAgeUpgrades(true))
      {
         aiEcho("Enabling age upgrades");
         aiSetPauseAllAgeUpgrades(false);
      }
   }
}



// cvMaxGathererPop set function:  No cleanup needed when this changes, just including the function for consistency
void setMaxGathererPop(int value = -1)
{
   cvMaxGathererPop = value;
}


// cvMaxMilPop set function
void setMaxMilPop(int value = -1)
{
   cvMaxMilPop = value;
}


// cvMaxSettlements set function
void setMaxSettlements(int value = 100)
{
   cvMaxSettlements = value;
}

// cvSetMaxTradePop set function
void setMaxTradePop(int value = -1)
{
   if (cvMaxTradePop == -1)
      aiPlanSetVariableInt(gTradePlanID, cTradePlanTradeUnitTypeMax, 0, gMaxTradeCarts);
   else
      aiPlanSetVariableInt(gTradePlanID, cTradePlanTradeUnitTypeMax, 0, cvMaxTradePop);

}


// cvOkToAttack set function.  Use this to set the variable at any time other than the initial setParameters() function.
void setOkToAttack(bool value = true)
{
   cvOkToAttack = value;

   if (value == true)     // We've decided to fight after all
   {
      aiEcho("cvOkToAttack is now true.");
      if (gLandAttackGoalID >= 0)      // We have an attack plan
         aiPlanSetVariableBool(gLandAttackGoalID, cGoalPlanIdleAttack, 0, false);       // Permit attacks
      if (gRushGoalID >= 0)  // We have a rush attack plan
         aiPlanSetVariableBool(gRushGoalID, cGoalPlanIdleAttack, 0, false);       // Authorize the rush
   }
   else                          // We're tired of fighting
   {
      aiEcho("cvOkToAttack is now false.");
      if (gLandAttackGoalID >= 0)      // We have an attack plan
         aiPlanSetVariableBool(gLandAttackGoalID, cGoalPlanIdleAttack, 0, true);       // Prevent attacks
      if (gRushGoalID >= 0)  // We have a rush attack plan
         aiPlanSetVariableBool(gRushGoalID, cGoalPlanIdleAttack, 0, true);       // Prevent rush
   }
}


// cvOkToBuild set function, used to give/revoke AI permission to build.
void setOkToBuild(bool value = true)
{
   cvOkToBuild = value;
   aiSetAllowBuildings(cvOkToBuild);
}

// cvOkToBuildTowers set function.  Send a 0 to turn off tower building.  Send a positive integer to have it start building towers. 
void setOkToBuildTowers(int quantity = 0)
{
   if (quantity <= 0)
   {
      cvOkToBuildTowers = false;
      gBuildTowers = false;
      gTargetNumTowers = 0;
   }
   else
   {
      towerInBase("TowerBuild", false, quantity, cMilitaryEscrowID); // build towers
      gTargetNumTowers = quantity;
      gBuildTowers = true;
      cvOkToBuildTowers = true;
      xsEnableRule("towerUpgrade");
   }
}

// cvOkToBuildWalls set function.  True turns on wall building.  False turns it off.  True makes it build walls, whether it wanted to or not
void setOkToBuildWalls(bool value = true)
{
   if (value == true)
   {
      cvOkToBuildWalls = true;
      xsEnableRule("wallUpgrade");
      gWallPlanID = aiPlanCreate("WallInBase", cPlanBuildWall);
      if (gWallPlanID != -1)
      {
         aiPlanSetVariableInt(gWallPlanID, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeRing);
         aiPlanAddUnitType(gWallPlanID, kbTechTreeGetUnitIDTypeByFunctionIndex(cUnitFunctionBuilder, 0), 1, 1, 1);
         aiPlanSetVariableVector(gWallPlanID, cBuildWallPlanWallRingCenterPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
         aiPlanSetVariableFloat(gWallPlanID, cBuildWallPlanWallRingRadius, 0, 45.0 - (10.0*cvRushBoomSlider));
         aiPlanSetVariableInt(gWallPlanID, cBuildWallPlanNumberOfGates, 0, 5);
         aiPlanSetBaseID(gWallPlanID, kbBaseGetMainID(cMyID));
         aiPlanSetEscrowID(gWallPlanID, cMilitaryEscrowID);
         aiPlanSetDesiredPriority(gWallPlanID, 100);
         aiPlanSetActive(gWallPlanID, true);
         //Enable our wall gap rule, too.
         xsEnableRule("fillInWallGaps");

         if (cMyCulture != cCultureAtlantean)      // Two extra one-vill wall plans let them leapfrog...faster wall construction
         {
            int wallPlanID2 = aiPlanCreate("WallInBase2", cPlanBuildWall);
            aiPlanSetVariableInt(wallPlanID2, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeRing);
            aiPlanAddUnitType(wallPlanID2, kbTechTreeGetUnitIDTypeByFunctionIndex(cUnitFunctionBuilder, 0), 1, 1, 1);
            aiPlanSetVariableVector(wallPlanID2, cBuildWallPlanWallRingCenterPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
            aiPlanSetVariableFloat(wallPlanID2, cBuildWallPlanWallRingRadius, 0, 45.0 - (10.0*cvRushBoomSlider));
            aiPlanSetVariableInt(wallPlanID2, cBuildWallPlanNumberOfGates, 0, 5);
            aiPlanSetBaseID(wallPlanID2, kbBaseGetMainID(cMyID));
            aiPlanSetEscrowID(wallPlanID2, cMilitaryEscrowID);
            aiPlanSetDesiredPriority(wallPlanID2, 100);
            aiPlanSetActive(wallPlanID2, true);

            int wallPlanID3 = aiPlanCreate("WallInBase3", cPlanBuildWall);
            aiPlanSetVariableInt(wallPlanID3, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeRing);
            aiPlanAddUnitType(wallPlanID3, kbTechTreeGetUnitIDTypeByFunctionIndex(cUnitFunctionBuilder, 0), 1, 1, 1);
            aiPlanSetVariableVector(wallPlanID3, cBuildWallPlanWallRingCenterPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
            aiPlanSetVariableFloat(wallPlanID3, cBuildWallPlanWallRingRadius, 0, 45.0 - (10.0*cvRushBoomSlider));
            aiPlanSetVariableInt(wallPlanID3, cBuildWallPlanNumberOfGates, 0, 5);
            aiPlanSetBaseID(wallPlanID3, kbBaseGetMainID(cMyID));
            aiPlanSetEscrowID(wallPlanID3, cMilitaryEscrowID);
            aiPlanSetDesiredPriority(wallPlanID3, 100);
            aiPlanSetActive(wallPlanID3, true);
         }

      }
   }
   else
   {
      cvOkToBuildWalls = false;
      int planID = aiPlanGetIDByTypeAndVariableType(cPlanBuildWall, cBuildWallPlanWallType, cBuildWallPlanWallTypeRing, true);
      aiPlanDestroy(planID);
      xsDisableRule("fillInWallGaps");
   }
}


// cvOkToChat set function.  Can be used any time
void setOkToChat(bool value = true)
{
   cvOkToChat = value;
}


// cvOkToGatherRelics set function.  Can be used any time
void setOkToGatherRelics(bool value = true)
{
   if (value == true)   // turning it on
   {
      cvOkToGatherRelics = true;
      gRelicGatherPlanID=aiPlanCreate("Relic Gather", cPlanGatherRelic);
      int gatherRelicType = cUnitTypeHero;
      if (cMyCulture == cCultureAtlantean)
         gatherRelicType = cUnitTypeOracleHero;
      if (cMyCulture == cCultureEgyptian)
         gatherRelicType = cUnitTypePharaoh;
      if (cMyCulture == cCultureNorse)
         gatherRelicType = cUnitTypeHeroNorse;

      if (gRelicGatherPlanID >= 0)
      {
         aiPlanAddUnitType(gRelicGatherPlanID, gatherRelicType, 1, 1, 1);
         aiPlanSetVariableInt(gRelicGatherPlanID, cGatherRelicPlanTargetTypeID, 0, cUnitTypeRelic);
		   aiPlanSetVariableInt(gRelicGatherPlanID, cGatherRelicPlanDropsiteTypeID, 0, cUnitTypeTemple);
         aiPlanSetBaseID(gRelicGatherPlanID, kbBaseGetMainID(cMyID));
         aiPlanSetDesiredPriority(gRelicGatherPlanID, 100);
		   aiPlanSetActive(gRelicGatherPlanID);
      }
   }

   if (value == false)
   {
      aiPlanDestroy(gRelicGatherPlanID);
      cvOkToGatherRelics = false;
   }
}

// cvOkToTrainArmy set function.  Use this to set the variable at any time other than the initial setParameters() function.
void setOkToTrainArmy(bool value = true)
{
   // Content TBD
}


// cvOkToResign set function.
void setOkToResign(bool value = true)
{
   if (value == true)
      xsEnableRule("ShouldIResign");
   // If false, the rule will automatically shut itself off.
}

 


void setOkToUseAge1GodPower(bool value = true)
{
   if (gAge1GodPowerPlanID >= 0)
      aiPlanSetActive(gAge1GodPowerPlanID, value);
}

void setOkToUseAge2GodPower(bool value = true)
{
   if (gAge2GodPowerPlanID >= 0)
      aiPlanSetActive(gAge2GodPowerPlanID, value);
}

void setOkToUseAge3GodPower(bool value = true)
{
   if (gAge3GodPowerPlanID >= 0)
      aiPlanSetActive(gAge3GodPowerPlanID, value);
}

void setOkToUseAge4GodPower(bool value = true)
{
   if (gAge4GodPowerPlanID >= 0)
      aiPlanSetActive(gAge4GodPowerPlanID, value);
}




// cvPlayerToAttack() set function.  
void setPlayerToAttack(int player = -1)
{
   cvPlayerToAttack = player;
   aiSetMostHatedPlayerID(player);
}


// *****************************************************************************
//
// Military Unit set functions
//
// *****************************************************************************
void setMilitaryUnitPrefs(int primaryType = -1, int secondaryType = -1, int tertiaryType = -1)
{
   if (primaryType == -1)     // Must specify 1 to use 2 and 3
   {
      secondaryType = -1;
      tertiaryType = -1;
   }
   if (secondaryType == -1)   // Must specify 1 and 2 before using 3
      tertiaryType = -1;

   // Clear current settings, if any
   if (cvPrimaryMilitaryUnit != -1)    // Clear current one
   {
      kbUnitPickSetPreferenceFactor(gRushUPID, cvPrimaryMilitaryUnit, 0.0);
      kbUnitPickSetPreferenceFactor(gLateUPID, cvPrimaryMilitaryUnit, 0.0);
   }
   if (cvSecondaryMilitaryUnit != -1)    // Clear current one
   {
      kbUnitPickSetPreferenceFactor(gRushUPID, cvSecondaryMilitaryUnit, 0.0);
      kbUnitPickSetPreferenceFactor(gLateUPID, cvSecondaryMilitaryUnit, 0.0);
   }
   if (cvTertiaryMilitaryUnit != -1)    // Clear current one
   {
      kbUnitPickSetPreferenceFactor(gRushUPID, cvTertiaryMilitaryUnit, 0.0);
      kbUnitPickSetPreferenceFactor(gLateUPID, cvTertiaryMilitaryUnit, 0.0);
   }

   // Store the new IDs
   cvPrimaryMilitaryUnit = primaryType;
   cvSecondaryMilitaryUnit = secondaryType;
   cvTertiaryMilitaryUnit = tertiaryType;

   // Set the new prefs, if any
   if (cvPrimaryMilitaryUnit != -1)
   {
      kbUnitPickSetPreferenceFactor(gRushUPID, cvPrimaryMilitaryUnit, 1.0);         // set the new value
      kbUnitPickSetPreferenceFactor(gLateUPID, cvPrimaryMilitaryUnit, 1.0);
   }
   if (cvSecondaryMilitaryUnit != -1)
   {
      kbUnitPickSetPreferenceFactor(gRushUPID, cvSecondaryMilitaryUnit, 0.7);         // set the new value
      kbUnitPickSetPreferenceFactor(gLateUPID, cvSecondaryMilitaryUnit, 0.7);
   }
   if (cvTertiaryMilitaryUnit != -1)
   {
      kbUnitPickSetPreferenceFactor(gRushUPID, cvTertiaryMilitaryUnit, 0.4);         // set the new value
      kbUnitPickSetPreferenceFactor(gLateUPID, cvTertiaryMilitaryUnit, 0.4);
   }

   if (cvPrimaryMilitaryUnit != -1)
   {
      kbUnitPickSetPreferenceWeight(gRushUPID, 50.0);                  // overwhelm cost, combat effectiveness 
      kbUnitPickSetPreferenceWeight(gLateUPID, 50.0);
   }
   else
   {
      kbUnitPickSetPreferenceWeight(gRushUPID, 1.0);                  // readjust preference weight for age-appropriate level
      kbUnitPickSetPreferenceWeight(gLateUPID, 1.0);
      if (kbGetAge() > cAge3)
         kbUnitPickSetPreferenceWeight(gLateUPID, 0.0);
   }
}

void setNumberMilitaryUnitTypes(int qty = -1)
{
   cvNumberMilitaryUnitTypes = qty;
   kbUnitPickSetDesiredNumberUnitTypes(gRushUPID, qty, 1, true); // qty units
   kbUnitPickSetDesiredNumberUnitTypes(gLateUPID, qty, gNumberBuildings, true); // qty units
}





// Tell the AI that transports will likely be needed.  For use only in overrideParameters().
void setTransportMap(bool value = false)
{
   gTransportMap = value;
}

// Tell the AI that this is a fish map...or not.  For use only in overrideParameters().
void setWaterMap(bool value = false)
{
   gWaterMap = value;
   aiSetWaterMap(gWaterMap);
}