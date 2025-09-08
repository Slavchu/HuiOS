# Config generation system
As this operating system is designed to be generic and easy to port, it was decided to implement a simple, merge-based config generation system.
To generate a minimal config, use the following command: ```./genconfig [board]_defconfig profile1 profile2 ...``` </br>
All generic board configs that apply to all profiles are located in the __huios/configs/__ folder and are applied in alphabetical order. All profiles are located in the __huios/profiles/__ directory and are applied in the order they are passed as arguments.

All configs and profiles are essentially partial configs and follow the structure below:
```makefile
key=value       # Overwrite an existing value
key+=" value1"  # Append a value

# Note: The separator used when appending is controlled by the user.
# In this example, it is a whitespace.
```