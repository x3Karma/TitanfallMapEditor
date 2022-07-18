global function SavePropMap
global function LoadPropMap

// a script that writes scripts..
const string HEADER = "global function InitMap%n\n\nglobal const MAP_%n_EXISTS = true\nglobal array<string> MAP_%n_PROPS\n\n" +
                    "void function InitMap%n() {\n"

const string FOOTER = "}\n\nvoid function AddMapProp( asset a, vector pos, vector ang, bool mantle, int fade)\n{\n" +
                    "	MAP_%n_PROPS.append(SerializeProp(a,pos,ang,mantle,fade))\n}\n\n" +
                    "void function AddMapPropV2( asset a, vector pos, vector ang, bool hidden, int fade)\n{\n" +
                    "	MAP_%n_PROPS.append(SerializePropV2(a,pos,ang,hidden,fade))\n}\n" +
                    "void function AddMapPropV3( asset a, vector pos, vector ang, bool hidden, int fade, int physics)\n{\n" +
                    "	MAP_%n_PROPS.append(SerializePropV3(a,pos,ang,hidden,fade,physics))\n}"

void function LoadPropMap( int map ) {
    if (MapExists( map )) {
        // Delete old map
        waitthread ClearPropMap()

        array<string> props = GetMapProps( map )
        foreach(string prop in props) {
            AddProp(DeserializeProp(prop))
        }
    }
}

// is this a stupid way to do this?
// yes but i cba
array<string> function GetMapProps( int map ) {
    if (map == 0) {
        return MAP_0_PROPS
    } else if (map == 1) {
        return MAP_1_PROPS
    } else if (map == 2) {
        return MAP_2_PROPS
    } else {
        return []
    }
    unreachable
}

bool function MapExists( int map ) {
    if (map == 0) {
        return MAP_0_EXISTS
    } else if (map == 1) {
        return MAP_1_EXISTS
    } else if (map == 2) {
        return MAP_2_EXISTS
    } else {
        return false
    }
    unreachable
}

void function SetMap( int map ) {
    if(map == 0) {
        MAP_0_PROPS.clear()
    } else if (map == 1) {
        MAP_1_PROPS.clear()
    } else if (map == 2) {
        MAP_2_PROPS.clear()
    }

    foreach(entity prop in GetAllProps()) {
        if(!IsValid(prop)) continue
        bool hidden = prop.GetScriptName == "editor_placed_prop_hidden"
        int physics = int(prop.kv.solid)

        if (map == 0) {
            MAP_0_PROPS.append(SerializePropV3(prop.GetModelName(), prop.GetOrigin(), prop.GetAngles(), hidden, 6000, physics))
        } else if (map == 1) {
            MAP_1_PROPS.append(SerializePropV3(prop.GetModelName(), prop.GetOrigin(), prop.GetAngles(), hidden, 6000, physics))
        } else if (map == 2) {
            MAP_2_PROPS.append(SerializePropV3(prop.GetModelName(), prop.GetOrigin(), prop.GetAngles(), hidden, 6000, physics))
        }
    }
}

void function SavePropMap( int map ) {
    array<string> code = []
    SetMap( map )
    foreach(entity prop in GetAllProps()) {
        if(!IsValid(prop)) continue
        code.append(GenerateCode(prop))
    }
    string path = "../R2Northstar/mods/Pebbers.MapEditor/mod/scripts/vscripts/maps/save_file" + map + ".nut"
    WriteOut(path, map, code)

}

void function WriteOut(string filename, int map, array<string> code) {
    string repHeader = Replace(HEADER, "%n", string(map), 4)
    string repFooter = Replace(FOOTER, "%n", string(map), 3)

    DevTextBufferClear()

    DevTextBufferWrite(repHeader)
    foreach(string line in code) {
        DevTextBufferWrite("	" + line + "\n")
    }
    DevTextBufferWrite(repFooter)

    DevP4Checkout( filename )
	DevTextBufferDumpToFile( filename )
	DevP4Add( filename )
	printt( "Wrote " + filename )
}

string function Replace(string toReplace, string placeholder, string to, int times) {
    string res = toReplace

    for (int i = 0; i < times; i++) {
        res = StringReplace(res, placeholder, to)
    }

    return res
}

string function GenerateCode( entity prop ) {
    vector origin = prop.GetOrigin()
    vector angles = prop.GetAngles()

    float x = origin.x
    float y = origin.y
    float z = origin.z

    float x1 = angles.x
    float y1 = angles.y
    float z1 = angles.z

    string pos = "< " + x + ", " + y + ", " + z + " >"
    string ang = "< " + x1 + ", " + y1 + ", " + z1 + " >"

    int physics = int(prop.kv.solid)
    bool hidden = prop.GetScriptName() == "editor_placed_prop_hidden"

    return "AddMapPropV3( " + prop.GetModelName() + ",  " + pos + ", " + ang + ", " + hidden +", 6000, " + physics + ")"
}