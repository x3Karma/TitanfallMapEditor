untyped

global function EditorModePlace_Init

#if SERVER
global function CC_Model
#elseif CLIENT
global function ServerCallback_UpdateModel
global function UICallback_SelectModel
global function ServerCallback_Angles
#endif

EditorMode function EditorModePlace_Init() 
{
	// save and load functions
	#if SERVER
	AddClientCommandCallback("model", CC_Model)
	AddClientCommandCallback("MoveOffset", CC_MoveOffset)
	AddClientCommandCallback("angles", CC_Angles)
	#endif

	#if CLIENT
	RegisterSignal("KeyUpReleased")
	RegisterSignal("KeyDownReleased")
	RegisterSignal("KeyForwardReleased")
	RegisterSignal("KeyBackwardReleased")
	RegisterSignal("KeyLeftReleased")
	RegisterSignal("KeyRightReleased")
	#endif

	return NewEditorMode(
		"#MODE_PLACE_NAME",
		"#MODE_PLACE_DESC",
		EditorModePlace_Activation,
		EditorModePlace_Deactivation,
		EditorModePlace_Place
	)
}

#if CLIENT
void function RegisterButtonCallbacks() {
	RegisterConCommandTriggeredCallback("+scriptCommand3", ChangeRotationToSurf)

	// (From Icepick)
	RegisterButtonPressedCallback( KEY_PAD_9, KeyPress_Up );
	RegisterButtonPressedCallback( KEY_PAD_7, KeyPress_Down );

	RegisterButtonPressedCallback( KEY_PAD_1, KeyPress_AngleX );
	RegisterButtonPressedCallback( KEY_PAD_3, KeyPress_AngleZ );

	RegisterButtonReleasedCallback( KEY_PAD_9, KeyRelease_Up );
	RegisterButtonReleasedCallback( KEY_PAD_7, KeyRelease_Down );

	RegisterButtonPressedCallback( KEY_PAD_8, KeyPress_Forward );
	RegisterButtonPressedCallback( KEY_PAD_2, KeyPress_Backward );
	RegisterButtonPressedCallback( KEY_PAD_4, KeyPress_Left );
	RegisterButtonPressedCallback( KEY_PAD_6, KeyPress_Right );
	RegisterButtonPressedCallback( KEY_PAD_5, KeyPress_Reset );

	RegisterButtonReleasedCallback( KEY_PAD_8, KeyRelease_Forward );
	RegisterButtonReleasedCallback( KEY_PAD_2, KeyRelease_Backward );
	RegisterButtonReleasedCallback( KEY_PAD_4, KeyRelease_Left );
	RegisterButtonReleasedCallback( KEY_PAD_6, KeyRelease_Right );
}

void function DeregisterButtonCallbacks() {
	DeregisterConCommandTriggeredCallback("+scriptCommand3",  ChangeRotationToSurf)

	DeregisterButtonReleasedCallback( KEY_PAD_9, KeyRelease_Up );
	DeregisterButtonReleasedCallback( KEY_PAD_7, KeyRelease_Down );

	DeregisterButtonPressedCallback( KEY_PAD_1, KeyPress_AngleX );
	DeregisterButtonPressedCallback( KEY_PAD_3, KeyPress_AngleZ );

	DeregisterButtonPressedCallback( KEY_PAD_9, KeyPress_Up );
	DeregisterButtonPressedCallback( KEY_PAD_7, KeyPress_Down );

	DeregisterButtonPressedCallback( KEY_PAD_8, KeyPress_Forward );
	DeregisterButtonPressedCallback( KEY_PAD_2, KeyPress_Backward );
	DeregisterButtonPressedCallback( KEY_PAD_4, KeyPress_Left );
	DeregisterButtonPressedCallback( KEY_PAD_6, KeyPress_Right );

	DeregisterButtonReleasedCallback( KEY_PAD_8, KeyRelease_Forward );
	DeregisterButtonReleasedCallback( KEY_PAD_2, KeyRelease_Backward );
	DeregisterButtonReleasedCallback( KEY_PAD_4, KeyRelease_Left );
	DeregisterButtonReleasedCallback( KEY_PAD_6, KeyRelease_Right );

	DeregisterButtonPressedCallback( KEY_PAD_5, KeyPress_Reset );
}
#endif

void function EditorModePlace_Activation(entity player)
{
	#if CLIENT
	RegisterButtonCallbacks()
	#endif
	thread StartNewPropPlacement(player)
}

void function EditorModePlace_Deactivation(entity player)
{
	#if CLIENT
	DeregisterButtonCallbacks()
	#endif
	if(IsValid(GetProp(player)))
	{
		GetProp(player).Destroy()
	}
}

void function EditorModePlace_Place(entity player)
{
	PlaceProp(player)
	thread StartNewPropPlacement(player)
}

void function StartNewPropPlacement(entity player)
{
	// incoming
	#if SERVER
	SetProp(
		player, 
		SpawnEditorProp(
			player.p.offsetVector,
			<0,0,0>,
			GetAsset(player),
			false,
			player.p.physics,
			true
		)
	)

	GetProp(player).NotSolid() // The visual is done by the client
	GetProp(player).Hide() // The visual is done by the client
	
	#elseif CLIENT
	SetProp(
		player, 
		CreateClientSidePropDynamic( 
			player.p.offsetVector, 
			<0, 0, 0>, 
			GetAsset(player)
		)
	)

	DeployableModelHighlight( GetProp(player) )

	GetProp(player).kv.renderamt = 255
	GetProp(player).kv.rendermode = 3
	GetProp(player).kv.rendercolor = "255 255 255 150"

	#endif

	thread PlaceProxyThink(player)
}

void function PlaceProp(entity player)
{

	#if SERVER
	//TODO: Convert to lightweight
	AddProp(GetProp(player))
	
	printl("hide: " + player.p.hideProps)
	if (!player.p.hideProps) {
		GetProp(player).Show()
		GetProp(player).SetScriptName("editor_placed_prop")
	} else {
		GetProp(player).SetScriptName("editor_placed_prop_hidden")
	}

	if (player.p.physics != -1) {
		GetProp(player).Solid()
	}
	GetProp(player).AllowMantle()
	
	// prints prop info to the console to save it
	vector myOrigin = GetProp(player).GetOrigin()
	vector myAngles = GetProp(player).GetAngles()

	printl(serialize("place", string(GetAsset(player)), myOrigin, myAngles))

	#elseif CLIENT
	if(player != GetLocalClientPlayer()) return;

	// TODO: Tell the server about the client's position so the delay isnt noticable

	GetProp(player).Destroy()
	SetProp(player, null)
	#endif
}

void function PlaceProxyThink(entity player)
{
	float gridSize = 16

	while( IsValid( GetProp(player) ) )
	{
		if(!IsValid( player )) return
		if(!IsAlive( player )) return

		vector or = GetProp(player).GetOrigin()
		vector an = GetProp(player).GetAngles()

		GetProp(player).SetModel( GetAsset(player) )

		TraceResults result = TraceLine(
			player.EyePosition() + 5 * player.GetViewForward(),
			player.GetOrigin() + 200 * player.GetViewForward(), 
			[player, GetProp(player)], // exclude the prop too
			TRACE_MASK_SHOT, TRACE_COLLISION_GROUP_PLAYER
		)

		vector origin = result.endPos

		origin.x = round(origin.x / gridSize) * gridSize
		origin.y = round(origin.y / gridSize) * gridSize
		origin.z = round(origin.z / gridSize) * gridSize

		vector offset = player.GetViewForward()
		vector ang = VectorToAngles(player.GetViewForward())

		// convert offset to -1 if value it's less than -0.5, 0 if it's between -0.5 and 0.5, and 1 if it's greater than 0.5

		float functionref(float val, float x, float y) smartClamp = float function(float val, float x, float y)
		{
			// clamp val circularly between x and y, which can be negative
			if(val < x)
			{
				return val + (y - x)
			}
			else if(val > y)
			{
				return val - (y - x)
			}
			return val
		}

		origin = origin + offset + player.p.offsetVector

		vector angles = -1 * VectorToAngles(player.GetViewVector() )

		angles.x = player.p.editorAngles.x
		angles.y = (floor(smartClamp((angles.y - 45), -360, 360) / 90) * 90)
		angles.z = (floor(smartClamp(ang.z + 45, -360, 360) / 90) * 90) + player.p.editorAngles.z
		
		GetProp(player).SetOrigin( origin )
		GetProp(player).SetAngles( angles )

		WaitFrame()
	}
}

void function RotationThink() {

}

vector function GetSafeGrid(vector grid) {
	grid.x = fabs(grid.x)
	grid.y = fabs(grid.y)
	grid.z = fabs(grid.z)

	//planes please dont fuck me
	if (grid.x == 0) grid.x = 0.01
	if (grid.y == 0) grid.y = 0.01
	if (grid.z == 0) grid.z = 0.01

	return grid
}


#if SERVER
bool function CC_Model(entity player, array<string> args) {
	if (args.len() == 0) return false
	SetModel(player, indexOf(GetAssets(), CastStringToAsset(args[0])))
	return true
}
#endif



void function SetModel(entity player, int idx) {
	player.p.selectedProp.selectedAsset = GetAssets()[idx]
	
	#if SERVER
	Remote_CallFunction_NonReplay(player, "ServerCallback_UpdateModel", idx)
	#endif
}

// INPUT HANDLER
#if CLIENT

// WHEN BUTTON IS PRESSED
void function KeyPress_Up( var button ) {
	MoveOffset(GetLocalClientPlayer(), 0, 0, 1 );
	thread KeyPress_Up_Threaded()
}
void function KeyPress_Down( var button ) {
	MoveOffset(GetLocalClientPlayer(), 0, 0, -1 );
	thread KeyPress_Down_Threaded()
}

void function KeyPress_Left( var button ) {
	MoveOffset(GetLocalClientPlayer(), 0, -1, 0 );
	thread KeyPress_Left_Threaded()
}
void function KeyPress_Right( var button ) {
	MoveOffset(GetLocalClientPlayer(), 0, 1, 0 );
	thread KeyPress_Right_Threaded()
}

void function KeyPress_Forward( var button ) {
	MoveOffset(GetLocalClientPlayer(), -1, 0, 0 );
	thread KeyPress_Forward_Threaded()
}
void function KeyPress_Backward( var button ) {
	MoveOffset(GetLocalClientPlayer(), 1, 0, 0 );
	thread KeyPress_Backward_Threaded()
}

void function KeyPress_Reset( var button ) {
	MoveOffset(GetLocalClientPlayer(), -1, -1, -1 );
}

void function KeyPress_AngleX( var button ) {
	vector angles = <0,0,0>
	angles.x = GetLocalClientPlayer().p.editorAngles.x

	if (angles.x == 360)
		GetLocalClientPlayer().ClientCommand("angles 45 0 0")
	else
		GetLocalClientPlayer().ClientCommand("angles " + ( angles.x + 45 ) + " 0 0")
}

void function KeyPress_AngleZ( var button ) {
	vector angles = <0,0,0>
	angles.z = GetLocalClientPlayer().p.editorAngles.z

	if (angles.z == 360)
		GetLocalClientPlayer().ClientCommand("angles 0 0 45")
	else
		GetLocalClientPlayer().ClientCommand("angles 0 0 " + ( angles.z + 45 ))
}

// WHEN BUTTON IS PRESSED AND HELD, ENDS WHEN BUTTON IS RELEASED
void function KeyPress_Up_Threaded() {
	GetLocalClientPlayer().EndSignal("KeyUpReleased")
	wait 0.5
	while (true)
	{
		MoveOffset(GetLocalClientPlayer(), 0, 0, 1 );
		wait 0.1
	}
}

void function KeyPress_Down_Threaded() {
	GetLocalClientPlayer().EndSignal("KeyDownReleased")
	wait 0.5
	while (true)
	{
		MoveOffset(GetLocalClientPlayer(), 0, 0, -1 );
		wait 0.1
	}
}

void function KeyPress_Left_Threaded() {
	GetLocalClientPlayer().EndSignal("KeyLeftReleased")
	wait 0.5
	while (true)
	{
		MoveOffset(GetLocalClientPlayer(), 0, -1, 0 );
		wait 0.1
	}
}
void function KeyPress_Right_Threaded() {
	GetLocalClientPlayer().EndSignal("KeyRightReleased")
	wait 0.5
	while (true)
	{
		MoveOffset(GetLocalClientPlayer(), 0, 1, 0 );
		wait 0.1
	}
}

void function KeyPress_Forward_Threaded() {
	GetLocalClientPlayer().EndSignal("KeyForwardReleased")
	wait 0.5
	while (true)
	{
		MoveOffset(GetLocalClientPlayer(), -1, 0, 0 );
		wait 0.1
	}
}
void function KeyPress_Backward_Threaded() {
	GetLocalClientPlayer().EndSignal("KeyBackwardReleased")
	wait 0.5
	while (true)
	{
		MoveOffset(GetLocalClientPlayer(), 1, 0, 0 );
		wait 0.1
	}
}

// WHEN BUTTON IS RELEASED
void function KeyRelease_Up( var button )
{
	GetLocalClientPlayer().Signal("KeyUpReleased")
}

void function KeyRelease_Down( var button )
{
	GetLocalClientPlayer().Signal("KeyDownReleased")
}

void function KeyRelease_Left( var button )
{
	GetLocalClientPlayer().Signal("KeyLeftReleased")
}

void function KeyRelease_Right( var button )
{
	GetLocalClientPlayer().Signal("KeyRightReleased")
}

void function KeyRelease_Forward( var button )
{
	GetLocalClientPlayer().Signal("KeyForwardReleased")
}

void function KeyRelease_Backward( var button )
{
	GetLocalClientPlayer().Signal("KeyBackwardReleased")
}
#endif

#if SERVER
bool function CC_MoveOffset(entity player, array<string> args) {
	MoveOffset(player, args[0].tofloat(), args[1].tofloat(), args[2].tofloat())
	return true
}
#endif
#if SERVER
bool function CC_Angles(entity player, array<string> args) {
	if (args.len() != 3) return false
	
	int x = args[0].tointeger()
	int y = args[1].tointeger()
	int z = args[2].tointeger()

	player.p.editorAngles = < x, y, z >

	Remote_CallFunction_NonReplay(player, "ServerCallback_Angles", x, y, z)
	return true
}
#endif

void function MoveOffset(entity player, float x, float y, float z) {
	if (x == -1 && y == -1 && z == -1) {
		player.p.offsetVector = <0,0,0>

		#if CLIENT
		player.ClientCommand("MoveOffset " + x + " " + y + " " + z)
		#endif
		return
	}

	float sensitivity = 16.0
	vector vec = <x, y, z> * sensitivity
	
	#if CLIENT
	player.ClientCommand("MoveOffset " + x + " " + y + " " + z)
	#endif

	player.p.offsetVector = player.p.offsetVector + vec
}

// CALLBACKS
#if CLIENT
void function ServerCallback_UpdateModel( int idx ) {
	if(idx == -1) {
		print("-1 bruh")
		return
	}
	entity player = GetLocalClientPlayer()

	player.p.selectedProp.selectedAsset = GetAssets()[idx]
}

void function ChangeRotationToSurf( var button ) {
	entity player = GetLocalClientPlayer()

	GetLocalClientPlayer().p.editorAngles = <0,0,35>
	player.ClientCommand("angles 0 0 35")
}

// Making angles floats would probably make it more complicated for users
void function ServerCallback_Angles( int x, int y, int z ) {
	// entity player = GetLocalClientPlayer()

	GetLocalClientPlayer().p.editorAngles = <x, y, z>
}

void function UICallback_SelectModel(string name) {
	GetLocalClientPlayer().ClientCommand("model models/" + name + ".mdl")
}
#endif
