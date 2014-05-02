// *****************************************************************************
// AoMNaiLoaderDefRush.xs
//
// Loader for Defensive Rusher personality.  
// Rush 90% - heavy rush
// Military 90% - heavy military bias
// Defense 90% - heavy defense bias
// Noise +/- 20%
// *****************************************************************************


include "AoMNaiCV.xs";      // The control variable definitions
include "AoMNai.xs";        // The whole AI complex
include "AoMNaiCVFuncs.xs"; // Control Variable set functions.

// *****************************************************************************
//
// setParameters()
//
// Do most of the control variable (cv) initial declarations here.
//
// *****************************************************************************
void setParameters(void)   // This function is called from main() before init() is run.
{
   aiEcho("Starting setParameters()");
   cvDoAutoSaves = true;              // Autosaves on

//   cvPrimaryMilitaryUnit = cUnitTypeToxotes;     // Main military unit must be toxotes
//   cvNumberMilitaryUnitTypes = 1;                // Only make one unit type, i.e. toxotes and nothing else

//   cvRushBoomSlider = (aiRandInt(201)-100);
//   cvRushBoomSlider = cvRushBoomSlider/100.0;            // Totally random, -1.0 to 1.0

//   cvMilitaryEconSlider = (aiRandInt(201)-100);
//   cvMilitaryEconSlider = cvMilitaryEconSlider/100.0;    // Random

//   cvOffenseDefenseSlider = (aiRandInt(201)-100);
//   cvOffenseDefenseSlider = cvOffenseDefenseSlider/100.0;// Random  

   cvRushBoomSlider = 0.9;
   cvMilitaryEconSlider = 0.9;
   cvOffenseDefenseSlider = -0.9;

   cvSliderNoise = 0.2;    // This amount is added or subtracted to/from each slider for some game-to-game variety.

   aiEcho("In setParameters, sliders are...");
   aiEcho("RushBoom "+cvRushBoomSlider+", MilitaryEcon "+cvMilitaryEconSlider+", OffenseDefense "+cvOffenseDefenseSlider);
}


// *****************************************************************************
//
// setOverrides()
//
// Override certain defaults here as indicated in the aomMKcv.xs file.
//
// *****************************************************************************
void setOverrides(void)    // This function is called from main() after init() is run.  Use it to 
                           // override any initial settings done in the main scripts.
{
   aiEcho("Starting setOverrides()");
}

