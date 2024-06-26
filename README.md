**EZ Voxel Builder**

This mod is designed to make placing, removing, copying and pasting Nodes (Blocks) easy. Simple commands are used to expedite the creation process. Once enabled, the mod works as follows:

- Bring up the command terminal ('/' key by default)
- Type 'b' for Build or 'c' for Copy followed by 3 parameters (ie. /b 10 10 6)
- The parameters are 'Nodes Forward' 'Nodes Right' 'Nodes Up'
  - Note that parameter directions are based on the direction facing, not a specific direction like 'North'
  - The first position starts with the node immediately in front of the player
- Using /b 10 10 6 will build a structure 10 nodes forward by 10 nodes to the right by 6 nodes tall
  - Note that the structure built will be of the node currently being wielded by the player
  - If not wielding anything, the 'structure' built will be of "air", effectively deleting an area of nodes
- Using /c 10 -10 6 will copy 10 nodes forward by 10 nodes to the left by 6 nodes tall
  - A negative number for parameter 2 will cause nodes to be built to the left instead of to the right
  - A negative number for parameter 3 will cause nodes to be built below instead of above
- Once an area has been copied, the player can type '/p' to paste the identical area in a new location and rotation
- If desired, type '/pm' to paste the copied area as a mirror image
- Type '/u' to undo the previous build or paste action
- Type '/help' for more information