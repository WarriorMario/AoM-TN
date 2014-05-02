// *****************************************************************************
// AoMNaiCV.xs 
//
// Control Variable header file.
//
// Use these variables as indicated to control the general-purpose AI behavior.
// Do not make changes to this file, it may be periodically updated and your 
// changes will be lost (or you'll miss the update).  All changes should be made
// to a copy of the loader file, one per scenario AI player.
//
// Browse through this file to see the available control variable names.
//
// *****************************************************************************

// In addition to the control variables, you may want to use these functions
// in setParameters().

      // aiSetDefaultStance(cUnitStanceDefensive); 
      // aiSetAttackResponseDistance(65.0);
      // aiSetMaxLOSProtoUnitLimit(4); // Set outpost limit

//==============================================================================
// Behavior modifiers - "control variable" sliders that range from -1 to +1 to adjust AI personalities.  Set them in setParameters().
extern float cvRushBoomSlider = 0.0;         // +1 is extreme rush, -1 is extreme boom.  Rush will age up fast and light
                                             // with few upgrades, and will start a military sooner.  Booming will hit
                                             // age 2 earlier, but will buy upgrades sooner, make more villagers, and 
                                             // will put a priority on additional settlements...but starts a military
                                             // much later.
extern float cvMilitaryEconSlider = 0.0;     // Works in conjunction with Rush/Boom.  Settings near 1 will put a huge
                                             // emphasis on military pop and resources, at the expense of the economy.
                                             // Setting it near -1 will put almost everything into the economy.  This
                                             // slider loses most of its effect in 4th age once all settlements are claimed
                                             // Military/Econ at 1.0, Rush/Boom at 1.0:  Quick jump to age 2, rush with almost no vill production.
                                             // Military 1, Rush/Boom -1:  Late to age 2, normal to age 3 with small military, grab 2 more settlements, then all military
                                             // Military/Econ -1, Rush/Boom +1:  Jump quickly to age 2, then jump quickly to age 3, delay upgrades and military.
                                             // Military/Econ -1, Rush/Boom -1:  Almost no military until all settlements are claimed.  Extremely risky boom.
extern float cvOffenseDefenseSlider = 0.0;   // Set high (+1+, causes all military investment in units.  Set low (-1), most military investment in towers and walls.
extern float cvSliderNoise = 0.3;            // The amount of random variance in slider variables.  Set it to 0.0 to have the values locked.  0.3 allows some variability.
                                             // Must be non-negative.  Resultant slider values will be clipped to range -1 through +1.

// Minor god choices.  These MUST be made in setParameters and not changed after that.  
// -1 means the AI chooses as it normally would.  List of god names follows.
extern int  cvAge2GodChoice = -1;
// cTechAge2Athena, cTechAge2Ares, cTechAge2Hermes, cTechAge2Anubis, cTechAge2Bast,
// cTechAge2Ptah, cTechAge2Forseti, cTechAge2Heimdall, cTechAge2Freyja,
// cTechAge2Okeanus, cTechAge2Prometheus, cTechAge2Leto
extern int  cvAge3GodChoice = -1;
// cTechAge3Apollo, cTechAge3Aphrodite, cTechAge3Hathor, cTechAge3Nephthys, cTechAge3Sekhmet
// cTechAge3Skadi, cTechAge3Bragi, cTechAge3Njord, cTechAge3Dionysos
// cTechAge3Hyperion, cTechAge3Rheia, cTechAge3Theia
extern int  cvAge4GodChoice = -1;
// cTechAge4Hera, cTechAge4Artemis, cTechAge4Hephaestus, cTechAge4Thoth
// cTechAge4Osiris, cTechAge4Horus, cTechAge4Hel, cTechAge4Baldr, cTechAge4Tyr,
// cTechAge4Helios, cTechAge4Hekate, cTechAge4Atlas

// DelayStart:  Setting this true will suspend ai initialization.  To resume, call setDelayStart(false).
extern bool    cvDelayStart = false;


// DoAutoSaves:  Setting this true will cause the AI to do an auto-save every 3 minutes.  Setting it false
// will eliminate auto saves.
// Use only in setParamters()
extern bool    cvDoAutoSaves = true;


// MaxAge:  Sets the age limit for this player.  Be careful to use cAge1...cAge4 constants, like cvMaxAge = cAge2 to 
// limit the player to age 2.  The actual age numbers used by the code are 0...3, so cAge1...cAge4 is much clearer.
// Set initially in setParameters(), then update dynamically with setMaxAge() if needed.
extern int     cvMaxAge = cAge5;


// MaxGathererPop:  Sets the maximum number of gatherers, but doesn't include fishing boats or trade carts (or dwarves?).
// Set initially in setParameters(), can be changed dynamically with setMaxGathererPop().
extern int     cvMaxGathererPop = -1;    // -1 turns it off, meaning the scripts can do what they want.  0 means no gatherers.

// MaxMilPop:  The maximum number of military UNITS (not pop slots) that the player can create.  
// Set initially in setParameters(), can be changed dynamically with setMaxMilPop().
extern int     cvMaxMilPop = -1;         // -1 turns it off, meaning the scripts can do what they want.  0 means no military.

// MaxSettlements:  The maximum number of settlements this AI player may claim.
// Set initially in setParameters(), can be changed dynamically with setMaxSettlements().
extern int     cvMaxSettlements = 100; // Way high, no limit really.

// MaxTradePop:  Tells the AI how many trade units to make.  May be changed via setMaxTradePop().  If set to -1, the AI decides on its own.
extern int     cvMaxTradePop = -1;

// OkToAttack:  Setting this false will prevent the AI from using its military units outside of its bases.
// Setting it true allows the AI to attack at will.  This variable can be changed during the course of the game
// by using setOkToAttack().
extern bool    cvOkToAttack = true;

// OkToBuild:  Gives the AI permission to build buildings.  Setting it false will prevent any building, including
// dropsites and houses...so only use it in scenarios where you will be providing the needed buildings.
// Set it initially in setParameters(), change it later if needed via setOkToBuild().
extern bool    cvOkToBuild = true;

// OkToBuildTowers:  Gives the AI permission to build Towers if it wants to.  Set it initially in setParamaters, change
// it later if needed using setOkToBuildTowers(int quantity), where quantity is the number of towers to make.
extern bool    cvOkToBuildTowers = true;

// OkToBuildWalls:  Gives the AI permission to build walls if it wants to.  Set it initially in setParamaters, change
// it later if needed using setOkToBuildWalls().  Setting it true later will FORCE wall-building...the AI decision on its own can 
// only happen at game start.
extern bool    cvOkToBuildWalls = true;


// OkToChat:  Setting this false will suppress the AI chats/taunts that it likes to send on age-up and attack events.
// Set initially in setParameters().  Can be changed dynamically with setOkToChat().
extern bool    cvOkToChat = true;


// OkToGatherRelics:  Setting this false will prevent the AI from gathering relics.
extern bool    cvOkToGatherRelics = true;

// OkToResign:  Setting this true will allow the AI to resign when it feels bad.  Setting it false will force it to play to the end.
extern bool    cvOkToResign = true;

// God power activation switches.  Set in setParameters(), can be modified later via cvOkToUseAge*GodPower() calls.
extern bool    cvOkToUseAge1GodPower = true;
extern bool    cvOkToUseAge2GodPower = true;
extern bool    cvOkToUseAge3GodPower = true;
extern bool    cvOkToUseAge4GodPower = true;

// OkToTrainArmy:  Not implemented, use cvMaxMilPop = 0 instead.

// OkToTrainGatherers:  Not implemented, see cvMaxGathererPop = 0 instead.

// PlayerToAttack:  -1 means not defined.  Number > 0 means attack that player number, overrides mostHatedPlayer.
extern int     cvPlayerToAttack = -1;     

// Military unit controls.  Read the entire comment block below the variable declarations, these must be used carefully.
extern int     cvPrimaryMilitaryUnit = -1;
extern int     cvSecondaryMilitaryUnit = -1;
extern int     cvTertiaryMilitaryUnit = -1;
extern int     cvNumberMilitaryUnitTypes = -1;
/*
   These variables can be used to tell the AI which military units to make, and how many types to make.  
   They should be set in setParameters if you want them to take effect immediately.  
   Later, they may be changed via the following calls:
      setMilitaryUnitPrefs(primary, secondary, tertiary), and setNumberMilitaryUnitTypes().
   Set each choice to -1 to turn it off, which then will allow the AI to make its normal choices.
   Set the numberMilitaryUnits to -1 (or use no parameter) to return the AI to its default.
   Example:
      // In setParameters(), start with an archer/cav army.
      cvNumberMilitaryUnitTypes = 2;
      cvPrimaryMilitaryUnit = cUnitTypeToxotes;
      cvSecondaryMilitaryUnit = cUnitTypeHippikon;

      // Then, in a rule that fires in age 3, and archer/counterCav/siege army
      setNumberMilitaryUnitTypes(3);
      setMilitaryUnitPrefs(cUnitTypeHoplite, cUnitTypeProdromos, cUnitTypePetrobolos);

      // Use an age 4 rule to make a hippikon/siege army
      setNumberMilitaryUnits(2);
      setMilitaryUnitPrefs(cUnitTypeHippikon, cUnitTypePetrobolos);  // No tertiary required, all parameters are options.

      // Finally, turn it off and let the AI choose:
      setNumberMilitaryUnits();  // No parameter means AI gets its choice.  Could also send -1 if you prefer.
      setMilitaryUnitPrefs();    // No parameter means clear them all.

  These functions work by massively distorting the unit picker's inherent preferences, so it's very important to turn
  them off when you're done.

  Primary must be used if secondary or tertiary are used.  For example, setting primary and secondary to -1 (off) and
  setting tertiary to cUnitTypeToxotes will have the effect of choosing nothing.  There is no way to tell 
  the AI to pick its own primary and secondary but override the tertiary.  You can set numberMiltiaryUnitTypes to 3 and only define 
  the primary, leaving it to pick the second and third.

  Finally, there is a side effect.  Hades may prefer archers initially.  If you tell him to make archers, he will.  When you tell him
  to later make up his own mind, his preference for archers is lost.  (There is no ai function to read the current preference value.)
*/

// Random map name.  Can be set in setParameters to make scenario AI's adopt map-specific behaviors.  Must be set in setParameters() to be
// used, there is no way to activate it later.

extern string cvRandomMapName="None";    


extern bool    cvTransportMap = false;    // Set this to true in setParameters() to tell AI to make transports.  Note: if left
                                          // false, the init() functions may set it true if its a watery map.  If you want
                                          // to be sure it won't use transports, call setTransportMap(false) in setOverrides() as well.
extern bool    cvWaterMap = false;        // Set this to true to make the AI think this is a fishable map.  Setting this false will *not* 
                                          // prevent the AI from fishing.  To do that, add these lines to your setOverrides() function:
                                                /*
	                                                gNumBoatsToMaintain = 0;
                                                   xsDisableRule("findFish"); 
                                                   xsDisableRule("fishing");
                                                */







