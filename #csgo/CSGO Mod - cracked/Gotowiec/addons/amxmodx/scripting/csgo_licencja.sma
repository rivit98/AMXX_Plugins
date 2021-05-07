#include amxmodx

public plugin_init()
{
    register_plugin("CSGO Mod: Licencja", "1.0", "d0naciak");
    return 0;
}

public plugin_natives()
{
    register_native("SprawdzLicencje05938", "nat_SprawdzLicencje", 1);
    return 0;
}

public nat_SprawdzLicencje()
{
	return 1;
}