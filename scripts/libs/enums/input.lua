local M = {}
M.AimMethod =
{
    UEVR = 1,
    HEAD = 2,
    RIGHT_CONTROLLER = 3,
    LEFT_CONTROLLER = 4,
    RIGHT_WEAPON = 5,
    LEFT_WEAPON = 6
}

M.PawnRotationMode =
{
    NONE = 1,
    RIGHT_CONTROLLER = 2,
    LEFT_CONTROLLER = 3,
	LOCKED = 4,
    SIMPLE = 5,
    ADVANCED = 6,
}

M.PawnPositionMode =
{
    NONE = 1,
    FOLLOWS = 2,
    ANIMATED = 3
}

return M