
PrecacheModel("models/bots/scout/bot_scout.mdl")
PrecacheModel("models/bots/soldier/bot_soldier.mdl")
PrecacheModel("models/bots/heavy_boss/bot_heavy_boss.mdl")
PrecacheModel("models/saxtron/bot_saxtron_v2.mdl")
PrecacheModel("models/bots/engineer/bot_engineer.mdl")

class BotStats
{
    constructor(__health, __scale, __model, __weaponModel, __speed, __projectile, __playbackRate, __animIdle, __animRun, __animAttack) //Two underscores
    {
        _health = __health;
        _scale = __scale;
        _model = __model;
        _weaponModel = __weaponModel;
        _speed = __speed;        
        _projectile = __projectile;
        _playbackRate = __playbackRate;
        _animIdle = __animIdle;
        _animRun = __animRun;
        _animAttack = __animAttack
    }

    _health         = null;
    _scale          = null;
    _model          = null;
    _weaponModel    = null;
    _speed          = null;
    _projectile     = null;
    _playbackRate   = null;
    _animIdle       = null;
    _animRun        = null;
    _animAttack     = null;
}

class BaseRobot
{
    constructor(stats)
    {
        health              = stats._health
        scale               = stats._scale
        model               = stats._model
        weaponModel         = stats._weaponModel
        speed               = stats._speed
        projectile          = stats._projectile
        animPlaybackRate    = stats._playbackRate
        animIdle            = stats._animIdle
        animMove            = stats._animRun
        animAttack          = stats._animAttack
    }

    health              = null
    scale               = null
    model               = null
    weaponModel         = null
    speed               = null
    projectile          = null
    animPlaybackRate    = null
    animIdle            = null
    animMove            = null
    animAttack          = null
}


function HolidayModifier(none, birthday = null, halloween = null, christmas = null, pyrovision = null)
{
    if (IsHolidayActive(0)) return none
    if (IsHolidayActive(1)) return birthday
    if (IsHolidayActive(9)) return halloween //Halloween or Full Moon
    if (IsHolidayActive(3)) return christmas
    if (IsHolidayActive(7)) return pyrovision
    return none
}

//Behavior bitmasks
const FOLLOWS_PATH = 1
const RANGED_ATTACK = 2
const TARGETS_FRIENDLIES = 4

//stats

scoutStats <- BotStats(
    500,                                //Health
    1,                                  //Scale
    "models/bots/scout/bot_scout.mdl",  //Model Path
    "models/weapons/c_models/c_bat.mdl",//Weapon Model Path
    160,                                //Move Speed
    null,                               //Projectile
    0.8,                                //Animation Speed
    "stand_MELEE",                      //Idle Animation
    "Run_MELEE_ALLCLASS"                //Run Animation
    "Jump_Start_melee"                  //Attack Animation
)

soldierStats <- BotStats(
    1000,                                   //Health
    1,                                      //Scale
    "models/bots/soldier/bot_soldier.mdl",  //Model Path
    null,                                   //Weapon Model Path
    160,                                    //Move Speed
    null,                                   //Projectile
    1,                                      //Animation Speed
    "Stand_MELEE",                          //Idle Animation
    "Run_MELEE"                             //Run Animation
    "Airwalk_PRIMARY"                       //Attack Animation
)

heavyStats <- BotStats(
    3000,                                   //Health
    1,                                      //Scale
    "models/bots/heavy/bot_heavy.mdl",      //Model Path
    null,                                   //Weapon Model Path
    160,                                    //Move Speed
    null,                                   //Projectile
    1,                                      //Animation Speed
    "Stand_MELEE",                          //Idle Animation
    "Run_MELEE"                             //Run Animation
    "Stand_Deployed_PRIMARY"                //Attack Animation
)

saxtonStats <- BotStats(
    5000,                                   //Health
    1,                                      //Scale
    "models/saxtron/bot_saxtron_v2.mdl",    //Model Path
    null,                                   //Weapon Model Path
    160,                                    //Move Speed
    null,                                   //Projectile
    1,                                      //Animation Speed
    "Stand_MELEE",                          //Idle Animation
    "Run_MELEE"                             //Run Animation
    "crouch_MELEE_ALLCLASS"                 //Attack Animation
)

engieStats <- BotStats(
    200,                                        //Health
    1,                                          //Scale
    "models/bots/engineer/bot_engineer.mdl",    //Model Path
    null,                                       //Weapon Model Path
    160,                                        //Move Speed
    null,                                       //Projectile
    1,                                          //Animation Speed
    "Stand_MELEE",                              //Idle Animation
    "run_MELEE_ALLCLASS"                        //Run Animation
    "a_grapple_pull_start"                      //Attack Animation
)

scoutBot        <- BaseRobot(scoutStats)
soldierBot      <- BaseRobot(soldierStats)
heavyBossBot    <- BaseRobot(heavyStats)
saxtonBot       <- BaseRobot(saxtonStats)
engieBot		<- BaseRobot(engieStats)


