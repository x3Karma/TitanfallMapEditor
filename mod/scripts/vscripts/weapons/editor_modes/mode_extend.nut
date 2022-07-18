global function EditorModeExtend_Init

global const EP = 0.01

#if CLIENT
struct {
    array<entity> highlightedEnts
    int distance = 1
} file
#endif

global enum ExDirection {
    Up,
    Down,
    Left,
    Right,
    Forward,
    Backward
}

EditorMode function EditorModeExtend_Init() 
{
    RegisterSignal("EditorModeExtendExit")
    #if SERVER
    AddClientCommandCallback("extend_distance", ClientCommand_ExtendDistance)
    #endif

    return NewEditorMode(
        "#MODE_EXTEND_NAME",
        "#MODE_EXTEND_DESC",
        EditorModeExtend_Activation,
        EditorModeExtend_Deactivation,
        EditorModeExtend_Extend
    )
}

void function EditorModeExtend_Activation(entity player)
{
    #if CLIENT
    RegisterButtonReleasedCallback( MOUSE_WHEEL_UP, IncreaseDistance );
	RegisterButtonReleasedCallback( MOUSE_WHEEL_DOWN, DecreaseDistance );

    thread EditorModeExtend_Think(player)
    #endif
}

void function EditorModeExtend_Deactivation(entity player)
{
    Signal(player, "EditorModeExtendExit")
    #if CLIENT
    DeregisterButtonReleasedCallback( MOUSE_WHEEL_UP, IncreaseDistance );
	DeregisterButtonReleasedCallback( MOUSE_WHEEL_DOWN, DecreaseDistance );

    ClearHighlighted()
    #endif
}

#if CLIENT
void function EditorModeExtend_Think(entity player) {
    player.EndSignal("EditorModeExtendExit")
    
    OnThreadEnd(
        function() : (player) {
            ClearHighlighted()
        }
    )
    
    while( true )
    {
        TraceResults result = GetPropLineTrace(player)
        ClearHighlighted()
        if (!IsValid(result.hitEnt)) {
            WaitFrame()
            continue
        }
        // This checks for it being a prop instead of the map
        array<string> check = split(string(result.hitEnt.GetModelName()), "/")
        if (check.len() > 0 && check[0] == "$\"models")
        {
            vector normal = Normalize(result.surfaceNormal)

            float dist = CalculateDistance(normal, result.hitEnt)

            printl("deb: " + RoundVec(normal))
            printl("dist: " + dist)
            printl("ang: " + result.hitEnt.GetAngles())
            vector res = normal * dist

            int maxD = file.distance
            for (int i = 0; i < maxD; i++) {
                int mult = i + 1
                vector pos = result.hitEnt.GetOrigin() + < res.x * mult, res.y * mult, res.z * mult >
                entity e = CreateClientSidePropDynamic(pos, result.hitEnt.GetAngles(), result.hitEnt.GetModelName())
                
                file.highlightedEnts.append(e)
                DeployableModelHighlight( e )
            }
        }

        WaitFrame()
    }
}

vector function GetDirFromNormal(vector normal, entity ent) {
    return <0,0,0>
}

void function ClearHighlighted() {
    foreach(entity e in file.highlightedEnts) {
        if (IsValid(e)) {
            e.Destroy()
        }
    }

    file.highlightedEnts.clear()
}

#endif

float function CalculateDistance(vector normal, entity ent) {
    float dist
    int d = FixForY(normal, ent)
    vector min = ent.GetBoundingMins() // This is relative
    vector max = ent.GetBoundingMaxs() // This is also relative
    
    switch(d)
    {
        case ExDirection.Up:
        case ExDirection.Down:
            dist = fabs( max.z - min.z );
            break;
        case ExDirection.Left:
        case ExDirection.Right:
            dist = fabs( max.y - min.y );
            break;
        case ExDirection.Forward:
        case ExDirection.Backward:
            dist = fabs( max.x - min.x );
            break;
    }

    return dist
}

int function FixForY(vector normal, entity ent) {
    float rotX = ent.GetAngles().x
    float rotY = ent.GetAngles().y
    float rotZ = ent.GetAngles().z

    int dir = NormalToDir(normal, ent)
    if (isBetween(rotZ, 45, 90)) {
        if (is90(rotY)) {    
            switch(dir) {
                case ExDirection.Up:
                    return ExDirection.Forward
                    break;
                case ExDirection.Down:
                    return ExDirection.Backward
                    break;
                case ExDirection.Forward:
                    return ExDirection.Up
                    break;
                case ExDirection.Backward:
                    return ExDirection.Down
                    break;
            }
        }
    }

    return dir
}


int function NormalToDir(vector normal, entity ent) {
    vector rounded = RoundVec(normal)
    printl("realn: " + normal)
    float rotX = ent.GetAngles().x
    float rotY = ent.GetAngles().y
    float rotZ = ent.GetAngles().z

    if (rounded.z == 1 || rounded.z == -1) {
        if (isBetween(rotZ, 45, 90)) {
            return ExDirection.Left
        }
        return ExDirection.Up
    }

    if (rounded.y == 1 || rounded.y == -1) {
        if (isBetween(rotZ, 45, 90)) {
            return ExDirection.Up
        }
        if (isBetween(rotZ, 0, 45) && is90(rotY)) {
            return ExDirection.Forward
        }
        return ExDirection.Left
    }

    if (rounded.x == 1 || rounded.x == -1) {
        return ExDirection.Forward
    }

    return -1
}

void function EditorModeExtend_Extend(entity player)
{
    #if SERVER
    TraceResults result = GetPropLineTrace(player)
    if (IsValid(result.hitEnt) && (result.hitEnt.GetScriptName() == "editor_placed_prop" || result.hitEnt.GetScriptName() == "editor_placed_prop_hidden" ))
    {
        vector normal = Normalize(result.surfaceNormal)
        float dist = CalculateDistance(normal, result.hitEnt)

        vector res = normal * dist

        int maxD = player.p.extendDistance
        for(int i = 0; i < maxD; i++) {
            int mult = i+1
            vector pos = result.hitEnt.GetOrigin() + < res.x * mult, res.y * mult, res.z * mult >
        
            PlaceProp(player, result.hitEnt.GetModelName(), pos, result.hitEnt.GetAngles())
        }
    }
    #endif
}

#if SERVER
bool function ClientCommand_ExtendDistance(entity player, array<string> args) {
    int a = args[0].tointeger()

    player.p.extendDistance = a
    return true
}
#endif

void function PlaceProp(entity player, asset ass, vector origin, vector angles)
{
    #if SERVER
    entity e = SpawnEditorProp(origin, angles, ass, player.p.hideProps, player.p.physics)

    AddProp(e)

    printl(serialize("place", string(GetAsset(player)), origin, angles))
    #elseif CLIENT
    if(player != GetLocalClientPlayer()) return;

    ClearHighlighted()
    #endif
}

vector function RoundVec(vector a) {
    vector normal = a
    normal.x = expect float(RoundToNearestInt(normal.x))
    normal.y = expect float(RoundToNearestInt(normal.y))
    normal.z = expect float(RoundToNearestInt(normal.z))
    return normal
}

vector function Zerofy(vector a) {
    vector ret = a

    if (a.x < EP) ret.x = 0
    if (a.y < EP) ret.y = 0
    if (a.z < EP) ret.z = 0

    return ret 
}


bool function isBetween(float x, float min, float max) {
    return x >= min && x <= max
}

bool function is90(float x) {
    return x == 90 || x == -90 || x == 270
}

#if CLIENT 
void function IncreaseDistance(var button) {
    file.distance++
    if (file.distance > 7) {
        file.distance = 7
    }

    entity player = GetLocalClientPlayer()
    player.ClientCommand("extend_distance " + file.distance)
}

void function DecreaseDistance(var button) {
    file.distance--
    if (file.distance <= 1) {
        file.distance = 1
    }
    
    entity player = GetLocalClientPlayer()
    player.ClientCommand("extend_distance " + file.distance)
}


#endif