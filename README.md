# RA3-Lua4.0



---

# Corona Mod LUA 4.0 Scripts for Custom Maps

This repository contains LUA 4.0 scripts and tools specifically designed for custom maps developed exclusively for the *Corona* mod, a highly popular *Red Alert 3* modification celebrated for its distinctive Chinese-inspired themes.

Notably, music from the *Corona* mod gained widespread attention when it was featured during the 2024 Olympic Games and a live broadcast from China’s Tiangong Space Station on CCTV. This crossover highlights the cultural significance of the mod, with its influence extending beyond gaming to global real-world events.

---

MOD official download site: https://cor-games.com/resource

MOD official promotion account: https://space.bilibili.com/400315239?


MOD promotion account(international): https://www.youtube.com/@ra3coronadevelopers863

---

Currently, the code includes a fire control system for various long range artillery units and an automatic evacuation system for various aircraft units. As development continues, more features and content may be added in future updates.

The FCS currently have 3 compontents: target prioritization, fire deconfliction, and target reallocation.  
 
  

---



















# Corona Fire Control System Algorithm v1

- Author: Inertia
- Date: November 16, 2024

## Introduction  
This algorithm centers around **artillery groups**, using dynamic grouping, target prioritization, and target allocation to achieve optimal firepower efficiency. It is designed to handle multiple artillery units, improve the effectiveness of artillery groups against enemy targets, and minimize firepower conflict and resource waste.  
**Entry function**: `groupArtilleryAndAllocateTargets`

---

## Algorithm Workflow  

### 1. **Artillery Status Check**  
- Iterate through the artillery list and check the status of each artillery unit:
  - **Survivability Check**: If an artillery unit is destroyed, it is removed from the list.
  - **Target Reallocation Check**: If an artillery unit requires reallocation (determined by `shouldReallocateArtillery`), then:
    - Reset its target allocation state, enabling it to participate in a new allocation cycle immediately.

---

### 2. **Artillery Grouping**  
- For artillery units that are unallocated and ungrouped, perform position checks:
  - **Distance Threshold**: Determine whether artillery units are close enough based on `artillery_grouping_range_threshold`.
  - **Group Formation**: Combine units meeting the criteria into a group, referred to as an **artillery group**.

---

### 3. **Target Prioritization**  
For each artillery group, perform the following:  
- Call the prioritization function `_prioritizeTargetsForGroup`:
  - Analyze targets based on factors such as threat level and proximity to the artillery units, generating a prioritized target list (Target Lists).
  - **Target List Structure**:
    - High-priority target list
    - Secondary-priority target list

---

### 4. **Target Allocation and Conflict Resolution**  
For each artillery group and its prioritized target list, execute the following:  
- Call the target allocation function `_allocateTargetsToGroup`:
  - Iterate through the target list to allocate targets to each artillery unit in the group.
  - **Conflict Resolution**: Ensure multiple artillery units do not concentrate on the same target, maximizing firepower coverage.

---

### 5. **Invalid Data Cleanup**  
- If changes occur in the artillery list (e.g., removed invalid artillery units), rebuild the list:
  - Call `_Rebuild_Table_with_Nils_Removed` to remove empty entries.
  - Update the size of the artillery list.

---

## Core Subsystems  

### **1. Target Prioritization System**  
- Generate a prioritized target list by analyzing target importance (e.g., threat level, distance).  
- Supports multi-level prioritization to ensure critical targets are addressed first.  

### **2. Fire Allocation and Conflict Resolution System**  
- Optimize the matching between artillery and targets:
  - Allocation rules ensure that all artillery units in a group are effectively assigned to targets.
  - Conflict resolution logic avoids multiple artillery units attacking the same target.

### **3. Target Reallocation System**  
- Quickly reassign targets to artillery units when targets are destroyed or lost:
  - Prevent artillery units from being idle for extended periods.
  - Dynamically select the next suitable target from the prioritized target list.

---

## Algorithm Advantages  
1. **Dynamic Grouping**: Artillery groups adjust in real time based on proximity, adapting to battlefield changes.  
2. **Efficient Prioritization**: Multi-level prioritization logic ensures that critical targets are addressed first.  
3. **Conflict Avoidance**: The allocation algorithm reduces resource waste and enhances overall firepower output efficiency.  
4. **Real-Time Adjustment**: Invalid data cleanup and target reallocation mechanisms ensure stable system operation.

---

## Overall Algorithm Flowchart  

```
1. Check Artillery Status ——>  
2. Dynamically Group Artillery ——>  
3. Generate Target Priority List ——>  
4. Allocate Targets and Resolve Conflicts ——>  
5. Cleanup Invalid Data  
```  

This algorithm is centered around **artillery groups**, achieving precise firepower management through dual optimization of grouping and allocation.  

---

