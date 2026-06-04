extends Node

# Persistent tracking variable: stores the string identifier of the last door or transition trigger 
# used by the player. This allows the game to determine the correct spawn position when loading into a new scene.
var coming_from: String = ""
