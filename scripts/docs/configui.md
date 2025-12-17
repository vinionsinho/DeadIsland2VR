## Config UI
Rename the files "example_config_1", "example_config_2", "example_config_3", "example_config_4" to ".lua" and rename all other examples to ".luax"<br/>

The uevrlib comes with a way to define imgui widget layouts using json instead of coding them by hand. This functionality can be used across multiple lua files and each file can access the other's widgets. This allows for modular code design where a general purpose feature can be developed with it's own config UI and then integrated into other modder's projects without interfering with the modder's code but giving the modder access to the config values if needed. The example files show how multiple files can define their own configuration tabs but access each others settings as needed.<br/>

The file "example_config_1.lua" contains examples of many of the json defined widgets available. For more information on using the config ui features see the comments in /libs/configui.lua<br/>

